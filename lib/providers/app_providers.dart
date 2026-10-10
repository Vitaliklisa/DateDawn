import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/circles.dart';
import '../core/models.dart';
import '../core/notifications.dart';
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
final invitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.email.isEmpty) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchInvitations(user.email);
});

/// Pending circle invitations addressed to the signed-in user's email.
final circleInvitationsProvider = StreamProvider<List<CircleInvitation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.email.isEmpty) return Stream.value(const []);
  return ref.watch(eventRepositoryProvider).watchCircleInvitations(user.email);
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
final notesProvider =
    StreamProvider.family<List<EventNote>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchNotes(eventId);
});

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
    return defaultTimeFormatFor(PlatformDispatcher.instance.locale);
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
