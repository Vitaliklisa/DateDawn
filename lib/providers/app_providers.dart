import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/circles.dart';
import '../core/models.dart';
import '../core/notifications.dart';
import '../core/recent_contacts.dart';
import '../core/time_format.dart';
import '../services/auth_service.dart';
import '../services/event_repository.dart';
import '../services/notification_service.dart';

/// Overridden in `main()` (and in tests) with a ready-to-use instance.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The Firestore-backed data layer: countdowns, circles, invitations, notes.
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    // Deliver inbox notifications into the recipient's Firestore subcollection.
    // Injected here rather than called directly inside the repository so the
    // data layer stays testable without a live Firestore instance.
    notificationSink: ({
      required userId,
      required title,
      required body,
      required kind,
    }) async {
      await ref.read(notificationServiceProvider).sendNotification(
            userId: userId,
            title: title,
            body: body,
            type: kind,
          );
    },
  );
});

/// The per-user data layer: the notification inbox, theme sync and avatars.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// The signed-in user, or `null`. `AsyncValue.loading` covers the first frame,
/// before Firebase has restored the persisted session.
///
/// `autoDispose` is deliberate under Riverpod 3: when the last listener goes
/// away (the app is backgrounded and the router's listener is the only one
/// left), the Firebase auth subscription is torn down instead of being kept
/// alive for the process lifetime, which is what avoids a leaked listener
/// across hot restart.
final activeAuthStateProvider = StreamProvider<AppUser?>((ref) {
  ref.keepAlive();
  return ref.watch(authServiceProvider).authStateChanges().map((user) {
    if (user != null) {
      // Keeps the public `users/{uid}` profile in step, which is what the email
      // lookup for invitations reads. Not awaited: it is best-effort and must
      // not delay sign-in.
      unawaited(ref.read(eventRepositoryProvider).syncUserProfile(user));
    }
    return user;
  });
}, isAutoDispose: true);

/// Just the user, with loading collapsed to `null` for widgets that only need
/// to branch on signed-in vs signed-out.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(activeAuthStateProvider).value;
});

/// Whether Firebase has finished restoring the persisted session.
///
/// `activeAuthStateProvider.value` is `null` both while that restore is in
/// flight *and* when the visitor is genuinely signed out. Anything that reads
/// data by uid must wait for this, or a page refresh briefly looks like an
/// empty account and the user's countdowns appear to have vanished.
final authResolvedProvider = Provider<bool>((ref) {
  final auth = ref.watch(activeAuthStateProvider);
  return !auth.isLoading && !auth.isRefreshing;
});

/// All countdowns visible to the signed-in user, nearest first.
///
/// Stays in `loading` until the session has been restored, so the home screen
/// shows its spinner rather than an empty list during the first frames after a
/// refresh. A local-only visitor (no account) gets an empty list rather than an
/// error: there is nothing to sync, and the UI invites them to sign in.
final eventsProvider = StreamProvider<List<CountdownEvent>>((ref) {
  if (!ref.watch(authResolvedProvider)) {
    // A stream that never emits and never closes, so the provider genuinely
    // stays in `loading` until the session is restored. Returning
    // `Stream.empty()` here completed the provider immediately, which resolved
    // it out of loading and let the home screen flash its empty state before
    // the real feed arrived — the reload looked like the countdowns were gone.
    return _neverEmits<List<CountdownEvent>>();
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchEvents(user.id);
});

/// A stream that stays open forever and never produces a value.
///
/// Used to hold an [AsyncValue] in its `loading` state across a session
/// restore, where an empty stream would complete the provider instead. The
/// controller is closed when the provider cancels its subscription, so nothing
/// is left dangling.
Stream<T> _neverEmits<T>() {
  final controller = StreamController<T>();
  controller.onCancel = controller.close;
  return controller.stream;
}

/// Pending invitations addressed to the signed-in user's email.
///
/// Invitations from someone this user has blocked are dropped here rather than
/// shown. `blockUser` clears the pending ones when the block is made, but a
/// block is also a standing refusal: an invite that arrives afterwards (an
/// older app version, a retry) must not reappear in the inbox of the person who
/// asked not to hear from them.
final invitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.email.isEmpty) return Stream.value(const []);
  final repo = ref.watch(eventRepositoryProvider);
  final blocked =
      ref.watch(blockedUsersProvider).value ?? const <BlockedUser>[];
  final blockedIds = blocked.map((b) => b.userId).toSet();
  return repo.watchInvitations(user.email).map(
        (invites) => invites
            .where((invite) => !blockedIds.contains(invite.invitedBy))
            .toList(),
      );
});

/// Pending circle invitations addressed to the signed-in user's email.
///
/// Couple invitations are accepted as soon as this live stream receives them,
/// so auto-join does not depend on an invitation card being built or visible.
/// A failed join remains in the stream for the inbox's retry action.
///
/// The join is claimed through [invitationSubmissionProvider] before it is
/// attempted. Without the claim this ran again on every emission — the invite is
/// still `pending` in the snapshot while the first join is in flight — and the
/// second attempt failed with "already been answered", which looked exactly like
/// the couple join not working. Invitations from someone the user has blocked
/// are dropped before they reach the auto-join.
final circleInvitationsProvider = StreamProvider<List<CircleInvitation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.email.isEmpty) return Stream.value(const []);
  final repository = ref.watch(eventRepositoryProvider);
  final blocked =
      ref.watch(blockedUsersProvider).value ?? const <BlockedUser>[];
  final blockedIds = blocked.map((b) => b.userId).toSet();
  return repository
      .watchCircleInvitations(user.email)
      .asyncMap((invitations) async {
    final visible = <CircleInvitation>[];
    for (final invitation in invitations) {
      // Blocking is mutual in effect: an invitation from someone the user has
      // blocked is dropped here as well as the countdown-invite path, or a
      // couple invite would be auto-accepted straight through the block below.
      if (blockedIds.contains(invitation.invitedBy)) continue;
      if (!invitation.isCouple) {
        visible.add(invitation);
        continue;
      }

      // Claim before the write, not after it.
      //
      // This used to re-run on EVERY emission of the invitation stream: a
      // pending couple invite is still in the snapshot while the first join is
      // in flight, and nothing stopped a second `acceptCircleInvitation` for
      // the same id. The second one found the invitation already `accepted`,
      // `_guardCircleInvitation` threw "already been answered", the catch put the
      // card back on screen, and the join looked like it had failed — the
      // "couple doesn't work" report. The claim is shared with the inbox card, so
      // whichever path gets there first does the write exactly once.
      final claimKey = 'circle-${invitation.id}';
      final claims = ref.read(invitationSubmissionProvider.notifier);
      if (!claims.claim(claimKey)) continue;

      try {
        await repository.acceptCircleInvitation(
          invitation: invitation,
          userId: user.id,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
        );
        // Refresh what the join changed, so the circle and its countdowns appear
        // without waiting for the next unrelated rebuild.
        ref.invalidate(circlesProvider);
        ref.invalidate(eventsProvider);
      } catch (error) {
        debugPrint(
          '[datedawn] Could not auto-join couple circle '
          '${invitation.circleId} (${invitation.id}): $error',
        );
        // Released so the card's retry action can genuinely retry; the card is
        // shown only when the join did not happen.
        claims.release(claimKey);
        visible.add(invitation);
      }
    }
    return visible;
  });
});

/// Circles the signed-in user belongs to.
final circlesProvider = StreamProvider<List<Circle>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchCircles(user.id);
});

/// Members of one circle, hydrated with names and avatars.
final circleMembersProvider =
    StreamProvider.family<List<CircleMember>, String>((ref, circleId) {
  return ref.watch(eventRepositoryProvider).watchCircleMembers(circleId);
});

/// Answers to invitations the signed-in user sent — the "your friend joined"
/// feedback.
final responsesProvider = StreamProvider<List<InvitationResponse>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchResponses(user.id);
});

/// The signed-in user's notification inbox, live from
/// `users/{uid}/notifications`.
final appNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationServiceProvider).watchNotifications(user.id);
});

/// Unread invitation responses and inbox items for navigation badges.
final unreadResponseCountProvider = Provider<int>((ref) {
  final responses = ref.watch(responsesProvider).value ?? const [];
  final notifications = ref.watch(appNotificationsProvider).value ?? const [];
  return responses.where((r) => !r.read).length +
      notifications.where((n) => !n.isRead).length;
});

/// Everything awaiting the signed-in user's answer: countdown invites and
/// circle invites, in one list for a single inbox.
final pendingInviteCountProvider = Provider<int>((ref) {
  final events = ref.watch(invitationsProvider).value ?? const [];
  final circles = ref.watch(circleInvitationsProvider).value ?? const [];
  return events.length + circles.length;
});

/// Answers already being written, keyed by invitation id.
///
/// **This is the loop fix.** Every earlier guard lived in widget state, and
/// widget state cannot survive this case: `InvitationsInbox` is mounted in
/// several places at once (the home screen renders it more than once), each
/// instance builds its own card, and each card re-mounts as the Firestore
/// streams re-emit. A `bool _submitted` on a card is discarded and reset every
/// time that happens, so a settled invitation was re-submitted on the next
/// rebuild — indefinitely.
///
/// A provider outlives every one of those rebuilds and is shared by every
/// mounted copy, so the first card to claim an invitation id blocks all the
/// others, across remounts, for the life of the route.
class InvitationSubmission extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  /// Claims [key] atomically. Returns false if it was already claimed.
  ///
  /// Synchronous on purpose: `runAction` is async, so an `await` before the
  /// claim would let a second tap slip through in the same frame.
  bool claim(String key) {
    if (state.contains(key)) return false;
    state = {...state, key};
    return true;
  }

  /// Releases a claim so a genuine retry is possible after a failure.
  void release(String key) {
    if (!state.contains(key)) return;
    state = {...state}..remove(key);
  }
}

final invitationSubmissionProvider =
    NotifierProvider<InvitationSubmission, Set<String>>(
        InvitationSubmission.new);

/// Participants of one event, live.
final participantsProvider =
    StreamProvider.family<List<Participant>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchParticipants(eventId);
});

/// Notes on one event, live, oldest first.
///
/// Notes written by someone this user has blocked are filtered out. Blocking
/// removes the person from the countdown, but a note they wrote before that is
/// still a document — and "stop seeing them" has to mean their content too.
final notesProvider =
    StreamProvider.family<List<EventNote>, String>((ref, eventId) {
  final blocked =
      ref.watch(blockedUsersProvider).value ?? const <BlockedUser>[];
  if (blocked.isEmpty) {
    return ref.watch(eventRepositoryProvider).watchNotes(eventId);
  }
  final blockedIds = blocked.map((b) => b.userId).toSet();
  return ref.watch(eventRepositoryProvider).watchNotes(eventId).map(
      (notes) => notes.where((n) => !blockedIds.contains(n.userId)).toList());
});

/// People the signed-in user has invited before, most recently invited first.
///
/// This is what the invite field suggests as you type, so the address you typed
/// on the last countdown is offered on the next one instead of being retyped.
/// Empty while signed out, since there is nothing to remember against.
final recentContactsProvider = StreamProvider<List<RecentContact>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchRecentContacts(user.id);
});

/// How long the blocked list waits for its first snapshot before it becomes a
/// retryable error.
///
/// Not a production length: it only has to be longer than a normal Firestore
/// round-trip, and the watchdog it feeds is the reason the screen cannot sit on
/// a spinner forever. Overridden in tests, so they do not wait for it.
final blockedUsersLoadTimeoutProvider =
    Provider<Duration>((ref) => const Duration(seconds: 10));

/// People the signed-in user has blocked, newest first.
///
/// Blocking is required by Google Play's UGC policy, and a block is only honest
/// if the person can see it happened and can undo it — this is the list behind
/// Settings → Blocked people.
///
/// **Every state has to end.** A plain `StreamProvider` over `snapshots()` has
/// three ways to sit in `loading` for ever, and the blocked screen hit all
/// three:
///
///  * a refused listener (the rules could not authorise the query) — the error
///    arrived, but nothing on screen offered a way forward;
///  * a listener that never emits and never errors — an offline client with no
///    cached data, or a session that has signed out underneath the screen;
///  * a stream whose first event is delivered after the user has navigated
///    away and back.
///
/// So this resolves explicitly: data when the stream answers, a visible error
/// with the real reason when it fails (never an empty list — "you blocked
/// nobody" and "we could not read your blocks" are different facts), and a
/// timeout so silence becomes an error you can retry rather than a spinner.
class BlockedUsers extends AsyncNotifier<List<BlockedUser>> {
  Timer? _watchdog;
  int _generation = 0;

  @override
  Future<List<BlockedUser>> build() async {
    final user = ref.watch(currentUserProvider);
    final authResolved = ref.watch(authResolvedProvider);
    if (user == null) {
      // Signed out, or the session is still being restored. Nothing to read;
      // the router's redirect covers both.
      return const [];
    }

    final generation = ++_generation;
    final completer = Completer<List<BlockedUser>>();

    void finish(FutureOr<List<BlockedUser>> result, {Object? error}) {
      if (completer.isCompleted) return;
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(result);
      }
    }

    // The first snapshot resolves the provider. The subscription stays live
    // afterwards, so blocking or unblocking elsewhere still re-emits — but a
    // refusal that arrives *after* data must not turn a working list into an
    // error screen, because everything already on it is still true.
    //
    // It is deliberately not stored or cancelled here. Cancelling a
    // single-subscription stream throws while it is delivering an event, and a
    // dropped listener simply goes away with the notifier when the provider is
    // disposed or rebuilt. `finish` is idempotent, so a late event from a dead
    // read cannot resurrect a state that has already settled.
    ref.read(eventRepositoryProvider).watchBlockedUsers(user.id).listen(
          (people) => finish(people),
          onError: (Object error) => finish(const [], error: error),
        );
    ref.onDispose(() {
      _generation++;
      _watchdog?.cancel();
      _watchdog = null;
    });

    // Social logins carry an email in the token; a session restored before the
    // profile sync lands may not. Blocking from a countdown needs it, so hold
    // out for the session rather than reading with a half-filled account.
    final waitForEmail = user.email.isEmpty && !authResolved;

    // A plain `Future.timeout` would be wrong here: its internal race can leave
    // the underlying future with no listener if the provider is torn down at
    // the same moment, and Riverpod then surfaces a harmless "future completed
    // with an error" while the screen is already gone. An explicit timer that
    // only ever fails the completer once, and is cancelled with the provider,
    // has neither problem.
    _watchdog?.cancel();
    _watchdog = Timer(ref.read(blockedUsersLoadTimeoutProvider), () {
      if (completer.isCompleted) return;
      if (generation != _generation) {
        // A newer read took over; this one is no longer the answer, and must
        // not report an error for a request nobody is waiting on any more.
        completer.complete(const []);
        return;
      }
      completer.completeError(
        waitForEmail
            ? const DataFailure(
                'Your account is still being restored. Retry in a moment.')
            : const DataFailure(
                'Your blocked list took too long to load. Check your '
                'connection and try again.'),
      );
    });

    ref.onDispose(() {
      _watchdog?.cancel();
      _watchdog = null;
    });

    return completer.future;
  }

  /// Re-reads the list, leaving the error state for `loading`.
  ///
  /// `invalidateSelf`, not `ref.refresh` — a provider may not depend on itself,
  /// and refreshing its own future from inside the notifier is exactly that. The
  /// screen rebuilds from the new `loading` state and the read runs again.
  void retry() => ref.invalidateSelf();
}

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsers, List<BlockedUser>>(BlockedUsers.new);

/// Which countdown is pinned as the hero. `null` means "pick automatically":
/// the soonest upcoming one.
///
/// Riverpod 3 retired `StateProvider`; a plain `Notifier` is the replacement and
/// gives the same `ref.read(...).set(id)` ergonomics at the call sites.
class SelectedEventId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedEventIdProvider =
    NotifierProvider<SelectedEventId, String?>(SelectedEventId.new);

/// The countdown shown on the home screen.
///
/// Follows the web app's `pickFeatured`: an explicit selection wins, otherwise
/// the soonest future event, and if everything is in the past, the most recent
/// one.
final featuredEventProvider = Provider<CountdownEvent?>((ref) {
  final events = ref.watch(eventsProvider).value ?? const <CountdownEvent>[];
  if (events.isEmpty) return null;

  final selectedId = ref.watch(selectedEventIdProvider);
  if (selectedId != null) {
    for (final event in events) {
      if (event.id == selectedId) return event;
    }
  }

  final now = DateTime.now();
  final upcoming = events.where((e) => e.at.isAfter(now)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  if (upcoming.isNotEmpty) return upcoming.first;

  final past = [...events]..sort((a, b) => b.at.compareTo(a.at));
  return past.first;
});

/// Ticks once a second so every countdown face updates in lockstep, and the
/// whole app re-renders from one timer instead of one per widget.
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
      const Duration(seconds: 1), (_) => DateTime.now()).asBroadcastStream();
});

/// Theme mode loads from device storage immediately, then syncs to the signed-in
/// account's `users/{uid}.themeMode` so it follows them between devices.
///
/// Riverpod 3 retired `StateNotifierProvider`; `Notifier` is its successor and
/// removes the `state`-vs-`super` split that used to bite here.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _preferenceKey = 'theme_mode';

  String? _userId;
  int _accountRevision = 0;
  int _choiceRevision = 0;
  Future<void> _remoteWrites = Future<void>.value();

  @override
  ThemeMode build() {
    final user = ref.read(currentUserProvider);
    _userId = user?.id;
    ref.listen<AppUser?>(currentUserProvider, (previous, next) {
      _onUserChanged(next?.id);
    });
    unawaited(_restore(user?.id, _accountRevision, _choiceRevision));
    return ThemeMode.dark;
  }

  void set(ThemeMode mode) {
    state = mode;
    final choiceRevision = ++_choiceRevision;
    final accountRevision = _accountRevision;
    final userId = _userId;
    unawaited(_saveLocally(mode, choiceRevision));
    if (userId != null) {
      _queueRemoteSave(
        userId,
        mode,
        accountRevision,
      );
    }
  }

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void _onUserChanged(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    final revision = ++_accountRevision;
    unawaited(_restore(userId, revision, _choiceRevision));
  }

  Future<void> _restore(
    String? userId,
    int accountRevision,
    int choiceRevision,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final localMode =
          themeModeFromWire(preferences.getString(_preferenceKey));
      if (accountRevision != _accountRevision) return;

      if (localMode != null && choiceRevision == _choiceRevision) {
        state = localMode;
      }

      if (userId == null) return;
      final service = ref.read(notificationServiceProvider);
      await _syncRemote(userId, accountRevision, choiceRevision, service);
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not restore theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _syncRemote(
    String userId,
    int accountRevision,
    int choiceRevision,
    NotificationService service,
  ) async {
    try {
      final remoteWire = await service.fetchThemeMode(userId);
      if (accountRevision != _accountRevision || _userId != userId) return;

      if (choiceRevision != _choiceRevision) {
        _queueRemoteSave(userId, state, accountRevision);
        return;
      }

      final remoteMode = themeModeFromWire(remoteWire);
      if (remoteMode != null) {
        state = remoteMode;
        await _saveLocally(remoteMode, _choiceRevision);
      } else {
        _queueRemoteSave(userId, state, accountRevision);
      }
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not sync theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _saveLocally(ThemeMode mode, int choiceRevision) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (choiceRevision != _choiceRevision) return;
      await preferences.setString(_preferenceKey, themeModeToWire(mode));
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not save local theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _queueRemoteSave(
    String userId,
    ThemeMode mode,
    int accountRevision,
  ) {
    _remoteWrites = _remoteWrites.then((_) async {
      if (accountRevision != _accountRevision || _userId != userId) return;
      await ref
          .read(notificationServiceProvider)
          .saveThemeMode(userId, themeModeToWire(mode));
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('[datedawn] Could not save the theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Clock display format, stored per account so it follows the user between
/// devices — the same shape as [ThemeModeController].
///
/// The initial value follows the device locale rather than a hard-coded default,
/// so a phone set to a 24-hour region reads correctly before anything is chosen.
class TimeFormatController extends Notifier<TimeFormat> {
  static const _preferenceKey = 'time_format';

  String? _userId;
  bool _hasExplicitChoice = false;
  int _accountRevision = 0;
  Future<void> _remoteWrites = Future<void>.value();

  @override
  TimeFormat build() {
    final user = ref.read(currentUserProvider);
    _userId = user?.id;
    ref.listen<AppUser?>(currentUserProvider, (previous, next) {
      _onUserChanged(next?.id);
    });
    unawaited(_restore(user?.id, _accountRevision));
    // Resolved from the platform locale; replaced the moment a stored choice is
    // found, locally or remotely.
    //
    // Wrapped because this runs during the first widget build: anything thrown
    // here propagates out of `build` and takes the whole routed screen with it.
    // A clock preference is never worth a blank page, so an unexpected failure
    // degrades to the app's stated default instead.
    try {
      return defaultTimeFormatFor(PlatformDispatcher.instance.locale);
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not resolve the device time format: $error');
      debugPrintStack(stackTrace: stackTrace);
      return TimeFormat.twelveHour;
    }
  }

  void set(TimeFormat format) {
    state = format;
    _hasExplicitChoice = true;
    final accountRevision = _accountRevision;
    final userId = _userId;
    unawaited(_saveLocally(format));
    if (userId != null) {
      _queueRemoteSave(userId, format, accountRevision);
    }
  }

  void _onUserChanged(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    final revision = ++_accountRevision;
    unawaited(_restore(userId, revision));
  }

  Future<void> _restore(String? userId, int accountRevision) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final localFormat =
          timeFormatFromWire(preferences.getString(_preferenceKey));
      if (accountRevision != _accountRevision) return;
      // A local choice wins until the account is known to disagree; the remote
      // read below is what settles that.
      if (localFormat != null && !_hasExplicitChoice) {
        _hasExplicitChoice = true;
        state = localFormat;
      }

      if (userId == null) return;
      final remoteWire =
          await ref.read(notificationServiceProvider).fetchTimeFormat(userId);
      if (accountRevision != _accountRevision || _userId != userId) return;

      final remoteFormat = timeFormatFromWire(remoteWire);
      if (remoteFormat != null) {
        // The account is the source of truth once it holds a value: it is the
        // one that survives reinstalls and reaches every other device.
        state = remoteFormat;
        _hasExplicitChoice = true;
        await preferences.setString(
            _preferenceKey, timeFormatToWire(remoteFormat));
      } else if (_hasExplicitChoice) {
        // Nothing on the account yet — push whatever this device has.
        _queueRemoteSave(userId, state, accountRevision);
      }
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not restore time format: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _saveLocally(TimeFormat format) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, timeFormatToWire(format));
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not save local time format: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _queueRemoteSave(
    String userId,
    TimeFormat format,
    int accountRevision,
  ) {
    _remoteWrites = _remoteWrites.then((_) async {
      if (accountRevision != _accountRevision || _userId != userId) return;
      await ref
          .read(notificationServiceProvider)
          .saveTimeFormat(userId, timeFormatToWire(format));
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('[datedawn] Could not save the time format: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }
}

final timeFormatProvider = NotifierProvider<TimeFormatController, TimeFormat>(
    TimeFormatController.new);

/// Small helper so screens can run an action and show either a success or a
/// failure message without repeating try/catch.
Future<String?> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await action();
    if (successMessage != null) {
      messenger?.showSnackBar(SnackBar(content: Text(successMessage)));
    }
    return null;
  } on AuthFailure catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    return e.message;
  } on DataFailure catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    return e.message;
  } on FirebaseAuthException catch (e) {
    messenger?.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Something went wrong.')));
    return e.message;
  } on FirebaseException catch (e) {
    final message = e.code == 'permission-denied'
        ? 'You do not have permission to do that.'
        : (e.message ?? 'Something went wrong.');
    messenger?.showSnackBar(SnackBar(content: Text(message)));
    return message;
  } catch (e) {
    messenger
        ?.showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    return e.toString();
  }
}
