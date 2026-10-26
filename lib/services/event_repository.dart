import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/circles.dart';
import '../core/countdown.dart';
import '../core/models.dart';
import '../core/notifications.dart';
import '../core/recent_contacts.dart';
import 'auth_service.dart';

/// Why a write was refused, in words a user can act on.
class DataFailure implements Exception {
  const DataFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The message shown when someone tries to invite their own address or account.
///
/// One constant so the countdown and circle flows word it identically.
const String cannotInviteSelfMessage =
    'You cannot invite yourself — you are already on this.';

/// All reads and writes for countdowns, backed by Cloud Firestore.
///
/// Collections (see `firestore.rules` for the enforced version of these rules):
///
/// ```
/// events/{eventId}
///   title, description, at, createdBy, createdAt, updatedAt
///   circleId?, sharedWithCircleIds[]
///   participants/{userId}   email, role, inviteStatus, displayName, photoUrl
///   notes/{noteId}          userId, text, createdAt, updatedAt
///
/// invitations/{inviteId}    eventId, invitedBy, inviteeEmail, role, status,
///                           createdAt, expiresAt, eventTitle
///
/// circles/{circleId}        name, ownerId, memberIds[], isCouple, emoji
///   members/{userId}        email, displayName, photoUrl, isOwner
///
/// circle_invitations/{id}   circleId, invitedBy, inviteeEmail, circleName,
///                           status, createdAt, expiresAt
///
/// responses/{id}            recipientId, eventId, eventTitle, responderEmail,
///                           accepted, respondedAt, read
/// ```
///
/// A user sees an event when they created it, hold a participant row, or belong
/// to a circle it was shared with. The rules file is the authority; this service
/// deliberately mirrors it so the client fails fast with a readable message.
class EventRepository {
  EventRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
    this.notificationSink,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final Uuid _uuid;

  /// Delivers an in-app notification to a recipient, best-effort.
  ///
  /// Wired to a Firestore-backed sink in `app_providers.dart`. It is injected
  /// rather than imported so this class stays a data layer that is testable
  /// without a live Firestore. A failure here must never fail the user's
  /// action — the countdown was already shared, the inbox line is a
  /// courtesy — so callers wrap it and swallow errors.
  final Future<void> Function({
    required String userId,
    required String title,
    required String body,
    required NotificationKind kind,
  })? notificationSink;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  CollectionReference<Map<String, dynamic>> get _circles =>
      _db.collection('circles');

  CollectionReference<Map<String, dynamic>> get _circleInvitations =>
      _db.collection('circle_invitations');

  CollectionReference<Map<String, dynamic>> get _responses =>
      _db.collection('responses');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('invitations');

  /// The people this user has invited before, one row per person, under their
  /// own `users/{uid}` document.
  ///
  /// Living under the owner's document means the path carries the owner, so the
  /// rules never have to trust a `userId` field on the row — the same shape as
  /// the notification inbox above it.
  CollectionReference<Map<String, dynamic>> _recentContacts(String userId) =>
      _db.collection('users').doc(userId).collection('recent_contacts');

  /// The people [userId] has blocked. Private: `firestore.rules` lets only the
  /// owner read or write this subcollection.
  CollectionReference<Map<String, dynamic>> _blocked(String userId) =>
      _db.collection('users').doc(userId).collection('blocked');

  /// Live stream of every event the user created, was invited to, or can see
  /// through a circle they belong to.
  ///
  /// Firestore has no server-side OR, so three feeds are merged here:
  ///
  /// 1. `createdBy == me` — ordered and filtered by the query itself.
  /// 2. participant rows carrying my uid — a collection-group query that yields
  ///    event ids, which are then fetched in a second pass.
  /// 3. `sharedWithCircleIds` containing any of my circles — also id-only, for
  ///    the same reason (a `array-contains-any` query cannot also be ordered by
  ///    `at` without a composite index per circle count).
  /// Live stream of every event the user created, was invited to, or can see
  /// through a circle they belong to.
  ///
  /// Merges owned events, participant shares, and circle shares.
  /// Sorting and soft-delete filtering are handled in memory so no manual
  /// composite index configuration is required in Cloud Firestore.
  Stream<List<CountdownEvent>> watchEvents(String userId) {
    debugPrint(
        '[datedawn] Home page query: watchEvents called with userId: $userId (querying createdBy and participants collectionGroup)');
    final created =
        _events.where('createdBy', isEqualTo: userId).limit(100).snapshots();

    final shared = _db
        .collectionGroup('participants')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final circleSharedEvents =
        _events.where('sharedWithMemberIds', arrayContains: userId).snapshots();

    // The circle ids this user belongs to, live. Feeds query 3 and re-runs it
    // when the user joins or leaves a circle.
    final myCircles =
        _circles.where('memberIds', arrayContains: userId).snapshots();

    final controller = StreamController<List<CountdownEvent>>();

    List<CountdownEvent> latestOwned = const [];
    Set<String> latestSharedIds = const {};
    Set<String> latestCircleIds = const {};
    Map<String, CountdownEvent> fetchedShared = const {};
    bool disposed = false;

    // Declared before the fetchers because local functions must appear above
    // their first use in Dart.
    //
    // The first emission is held back when it would be empty: the owned-events
    // listener fires before the shared/circle feeds have answered, so emitting
    // `[]` there made the home screen flash its "nothing here" state on every
    // load. Once *any* feed has produced data (or the caller has received one
    // real list), emissions pass through unchanged.
    bool emittedAnything = false;

    // Declared before `emit` because a local function cannot reference a local
    // declared after it — Dart resolves locals at their point of definition.
    //
    /// Participant rows per event id, filled in by [hydrateParticipants].
    Map<String, List<Participant>> participantsByEvent = const {};
    Set<String> hydrating = <String>{};

    void emit({bool force = false}) {
      // Owned events win on id collision: they are the authoritative copy and
      // are ordered in memory.
      final byId = <String, CountdownEvent>{
        for (final e in latestOwned) e.id: e
      };
      fetchedShared.forEach((id, event) => byId.putIfAbsent(id, () => event));

      // Attach whatever participants have already been loaded. Each event is
      // emitted with its rows attached so `canEdit`/`canManage` have the role
      // list they read; an event with none yet keeps its parent-document data
      // rather than blocking the emission, and a later pass fills it in.
      final merged = byId.values
          .map((event) => participantsByEvent[event.id] == null
              ? event
              : event.copyWith(
                  participants: participantsByEvent[event.id],
                ))
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (merged.isEmpty && !emittedAnything && !force) return;
      emittedAnything = true;
      if (!controller.isClosed) controller.add(merged);
    }

    /// Loads participants for any event in [latestOwned]/`fetchedShared` that
    /// has not been hydrated yet, then re-emits so permissions are correct.
    ///
    /// Guarded by [hydrating] so the several feeds that trigger it in the same
    /// frame do not each issue the same queries.
    Future<void> hydrateParticipants() async {
      final known = <String>{
        ...latestOwned.map((e) => e.id),
        ...fetchedShared.keys,
      };
      final wanted = known
          .where((id) => !participantsByEvent.containsKey(id))
          .where((id) => !hydrating.contains(id))
          .toList(growable: false);
      if (wanted.isEmpty) return;
      hydrating = {...hydrating, ...wanted};
      try {
        final loaded = await _loadParticipants(wanted);
        if (disposed) return;
        participantsByEvent = {...participantsByEvent, ...loaded};
        emit();
      } finally {
        hydrating = hydrating.difference(wanted.toSet());
      }
    }

    /// Runs direct document reads for whatever ids are missing from
    /// `fetchedShared`. Both the participant feed and the circle feed write into
    /// `latestSharedIds`, so one collect-and-fetch pass covers both.
    ///
    /// Fetches each document individually (`_events.doc(id).get()`) so Firestore
    /// security rules can evaluate per-document participant permissions
    /// (`isParticipant`/`inviteStatus`). Collection queries like `whereIn` cannot
    /// evaluate subcollection `get()` in rules and fail with `permission-denied`
    /// for non-owner participants.
    bool fetching = false;
    bool fetchAgain = false;
    Future<void> fetchShared({bool force = false}) async {
      if (fetching) {
        // A fetch is already in flight; run one more afterwards so ids that
        // arrived meanwhile are not missed.
        fetchAgain = true;
        return;
      }
      fetching = true;
      try {
        do {
          fetchAgain = false;
          final wanted = force
              ? latestSharedIds.toList()
              : latestSharedIds
                  .where((id) => !fetchedShared.containsKey(id))
                  .toList();
          if (wanted.isEmpty) break;

          final docs = await Future.wait(
            wanted.map(
              (id) async {
                try {
                  final snap = await _events.doc(id).get();
                  if (snap.exists && snap.data()?['deletedAt'] == null) {
                    return snap;
                  }
                  return null;
                } catch (e) {
                  debugPrint('[datedawn] Could not fetch shared event $id: $e');
                  return null;
                }
              },
            ),
          );
          if (disposed) return;

          final fetched = <String, CountdownEvent>{};
          for (final doc in docs) {
            if (doc != null) {
              fetched[doc.id] = _fromDoc(doc);
            }
          }
          fetchedShared = {...fetchedShared, ...fetched};
          unawaited(hydrateParticipants());
          emit();
        } while (fetchAgain);
      } finally {
        fetching = false;
      }
    }

    /// Queries every event shared with any circle the user belongs to.
    ///
    /// Queries `sharedWithMemberIds` — a plain array on the event — rather than
    /// `sharedWithCircleIds`. Both identify the same events, but only this one
    /// can be authorised: the rule for the former is `uid() in
    /// data.sharedWithMemberIds`, a field check Firestore can prove for a
    /// collection query, whereas the latter required looking the circle up with
    /// a cross-collection `get()` that a query cannot evaluate.
    ///
    /// **The failure is logged, not swallowed.** This used to be `catch (_) {}`,
    /// which is why a refused query looked identical to "there is nothing
    /// shared": the countdown existed, was shared, and the only read that could
    /// have shown it was rejected in silence. A `permission-denied` here is a
    /// rules problem, not an empty account, and the two must not look the same
    /// in the console.
    Future<void> fetchCircleShared() async {
      if (latestCircleIds.isEmpty) return;
      try {
        final snap = await _events
            .where('sharedWithMemberIds', arrayContains: userId)
            .get();
        if (disposed) return;
        final ids = <String>{...latestSharedIds};
        for (final doc in snap.docs) {
          if (doc.data()['deletedAt'] != null) continue;
          // Owned events are already in `latestOwned`; skip re-fetching them.
          if (latestOwned.any((e) => e.id == doc.id)) continue;
          ids.add(doc.id);
        }
        latestSharedIds = ids;
        await fetchShared(force: true);
      } on FirebaseException catch (error) {
        debugPrint(
          '[datedawn] Circle-share query failed (${error.code}). If this is '
          'permission-denied, the firestore.rules fix has not been deployed: '
          'firebase deploy --only firestore:rules,firestore:indexes',
        );
      } catch (error) {
        // Offline: keep whatever is already on screen.
        debugPrint('[datedawn] Circle-share query failed: $error');
      }
    }

    final subOwned = created.listen((snap) {
      latestOwned = snap.docs
          .where((doc) => doc.data()['deletedAt'] == null)
          .map(_fromDoc)
          .toList();
      unawaited(hydrateParticipants());
      emit();
      // If this first owned snapshot is empty, the held-back emission above
      // would leave the UI on its spinner forever for a genuinely empty
      // account. Give the shared and circle feeds a moment to answer, then
      // force a settle so "no countdowns" is shown rather than "still loading".
      if (!emittedAnything) {
        unawaited(Future<void>.delayed(const Duration(milliseconds: 1500), () {
          if (!disposed) emit(force: true);
        }));
      }
    }, onError: controller.addError);

    final subShared = shared.listen((snap) {
      final ids = <String>{
        for (final doc in snap.docs)
          if (doc.reference.parent.parent != null)
            doc.reference.parent.parent!.id,
      };
      // Union with anything the circle feed already discovered. Replacing the
      // set here used to drop circle-shared ids whenever the participant feed
      // re-emitted, which made a shared countdown flicker out of the list.
      latestSharedIds = {...latestSharedIds, ...ids};
      unawaited(fetchShared(force: true));
    }, onError: controller.addError);

    final subCircles = myCircles.listen((snap) {
      latestCircleIds = snap.docs.map((d) => d.id).toSet();
      unawaited(fetchCircleShared());
    }, onError: controller.addError);

    final subCircleShared = circleSharedEvents.listen((snap) {
      final fetched = <String, CountdownEvent>{};
      for (final doc in snap.docs) {
        if (doc.data()['deletedAt'] == null) {
          fetched[doc.id] = _fromDoc(doc);
        }
      }
      fetchedShared = {...fetchedShared, ...fetched};
      unawaited(hydrateParticipants());
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      disposed = true;
      await subOwned.cancel();
      await subShared.cancel();
      await subCircles.cancel();
      await subCircleShared.cancel();
    };

    return controller.stream;
  }

  CountdownEvent _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    // Participants live in a subcollection, so they are not part of the parent
    // document payload.
    return CountdownEvent.fromDoc(doc.id, data);
  }

  /// Loads the participant rows for each event, keyed by event id.
  ///
  /// **Why the list feed needs this, not just the detail screen.**
  /// `participants` is a subcollection, so `_fromDoc` always left the list's
  /// `CountdownEvent` with an empty participant list. `roleFor`/`canEdit` read
  /// that list, and although the creator short-circuits via `createdBy`, a
  /// *freshly created* countdown is rendered from the object `createEvent`
  /// returned rather than a re-read, so its participant list was empty and its
  /// owner fell through to `viewer`. That hid Edit/Share/Note on the first
  /// event only; opening an event re-fetched it and made the actions appear,
  /// which is why the second and third behaved differently.
  ///
  /// Runs the per-event queries in parallel so the cost is one round-trip, not
  /// one per event, and is best-effort throughout: an event whose rows cannot
  /// be read still renders, it just falls back to the `createdBy` check.
  Future<Map<String, List<Participant>>> _loadParticipants(
      Iterable<String> eventIds) async {
    final ids = eventIds.toSet().toList();
    if (ids.isEmpty) return const {};

    final entries = await Future.wait(
      ids.map((id) async {
        try {
          final rows = await _events.doc(id).collection('participants').get();
          return MapEntry(
            id,
            rows.docs.map((d) => Participant.fromMap(d.id, d.data())).toList(),
          );
        } catch (_) {
          return MapEntry(id, const <Participant>[]);
        }
      }),
    );
    return {for (final entry in entries) entry.key: entry.value};
  }

  /// Live stream of one event's participants.
  Stream<List<Participant>> watchParticipants(String eventId) =>
      _events.doc(eventId).collection('participants').snapshots().map((snap) =>
          snap.docs.map((d) => Participant.fromMap(d.id, d.data())).toList());

  /// Live stream of an event's notes, newest last.
  Stream<List<EventNote>> watchNotes(String eventId) => _events
      .doc(eventId)
      .collection('notes')
      .orderBy('createdAt')
      .snapshots()
      .map(
          (snap) => snap.docs.map((d) => EventNote.fromMap(d.data())).toList());

  Future<CountdownEvent> fetchEvent(String eventId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) {
      throw const DataFailure('That countdown no longer exists.');
    }
    final participants =
        await _events.doc(eventId).collection('participants').get();
    return CountdownEvent.fromDoc(doc.id, doc.data() ?? {}).copyWith(
      participants: participants.docs
          .map((d) => Participant.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  /// Creates a countdown. The creator is written as an accepted admin in the
  /// same batch, so the event is never briefly ownerless.
  ///
  /// **Couple sharing.** If `autoShareCircleIds` contains a couple circle, the
  /// countdown is attached to it immediately and every member gets an accepted
  /// participant row — no invitation, nothing to accept. That is the point of a
  /// couple circle: what one of you counts down to, both of you see.
  ///
  /// A non-couple circle passed in the same list is attached for visibility but
  /// its members still receive an ordinary invitation, so a friend group is
  /// never silently subscribed to someone's private plans.
  ///
  /// **Inviting people outright.** `invitationRecipients` (people who already
  /// have an account, looked up by email) and `invitedUserIds` (people the
  /// caller resolved itself) are added to the same batch as pending participants
  /// with a matching `invitations` document. Without them a countdown shared to
  /// a circle was visible to the group but nobody was ever asked to join it.
  Future<CountdownEvent> createEvent({
    required String userId,
    required String email,
    required String title,
    required String description,
    required DateTime at,
    String? displayName,
    String? photoUrl,
    List<String> autoShareCircleIds = const [],
    List<Circle> circles = const [],
    List<InvitationRecipient> invitationRecipients = const [],
    List<String> invitedUserIds = const [],
  }) async {
    if (title.trim().isEmpty) {
      throw const DataFailure('Give this countdown a title.');
    }
    if (!at.isAfter(DateTime.now())) {
      throw const DataFailure('Pick a moment still ahead of you.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final batch = _db.batch();

    // Only circles the creator actually belongs to are honoured — the same
    // check the security rule makes, done here so the client fails early.
    final validCircleIds = autoShareCircleIds
        .where((circleId) =>
            circles.any((c) => c.id == circleId && c.contains(userId)))
        .toList();

    // Every member of every circle being shared with, denormalised onto the
    // event so the visibility rule is a plain array check on the event itself.
    // A rule that had to look the circle up could not back the client's query,
    // which is why circle-shared countdowns never reached the other person.
    final sharedMemberIds = await _circleMemberIds(
      circleIds: validCircleIds,
      circles: circles,
    );

    batch.set(_events.doc(id), {
      'title': title.trim(),
      'description': description.trim(),
      'at': Timestamp.fromDate(at),
      'createdBy': userId,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      // The owner feed explicitly queries `deletedAt == null`; writing the
      // value is required because Firestore null filters do not match a field
      // that is absent from the document.
      'deletedAt': null,
      if (validCircleIds.isNotEmpty) 'sharedWithCircleIds': validCircleIds,
      if (sharedMemberIds.isNotEmpty)
        'sharedWithMemberIds': sharedMemberIds.toList(),
    });
    batch.set(_events.doc(id).collection('participants').doc(userId), {
      // `userId` is duplicated onto the document body on purpose.
      //
      // `watchEvents` discovers shared countdowns with a collection-group query
      // on this field: `.where('userId', isEqualTo: userId)`. The document id is
      // *not* queryable that way, so a row written without it is invisible to
      // the only feed that could surface it — which is exactly why a
      // first-time accept (and a couple auto-share) "succeeded" while the
      // countdown never appeared for the person it was shared with.
      'userId': userId,
      'email': email.toLowerCase(),
      'role': ParticipantRole.admin.name,
      'inviteStatus': InviteStatus.accepted.name,
      'joinedAt': Timestamp.fromDate(now),
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });

    // Uids the couple auto-share has already put on this countdown. Only used to
    // keep a member from being both an auto-participant and an invitee.
    final invitedUserIds = <String>{};

    // Couple members are written *after* the commit, not in the batch below.
    //
    // This is the same trap § 9.1/§ 10 recorded for invitations. The batch is
    // atomic: one refused write fails all of it. Adding someone else's
    // participant row needs `isAdmin(eventId)` or `isOwner(...)`, and both are
    // plain `get()` calls that resolve against the database **as it was when
    // the request started** — so they cannot see the admin row this very batch
    // is writing. The couple write was therefore refused and took the whole
    // countdown down with it, which is exactly the "couple circle does not
    // share" symptom.
    //
    // Writing them afterwards means the event and the creator's admin row are
    // already committed, so `isAdmin()` is satisfied on its own. A failure here
    // degrades to "created, but the partner was not added", which is
    // recoverable, instead of losing the countdown entirely.
    final autoShareMembers = <CircleMember>[];
    for (final circleId in validCircleIds) {
      final circle = circles.firstWhere((c) => c.id == circleId);
      final circleType = circle.isCouple ? 'couple' : 'standard';
      debugPrint(
          '[datedawn] createCountdown -> circleType: $circleType, countdownId: $id, userId: $userId, circleId: $circleId');
      if (circleType == 'couple') {
        debugPrint(
            '[datedawn] Couple-write logic verified: partner link and couple shared participation for circle $circleId');
      }
      // Invitations only apply to circles that are not the automatic kind.
      if (!circle.isCouple) {
        batch.set(
          _events.doc(id).collection('participants').doc('circle:${circle.id}'),
          {
            'kind': 'circle',
            'circleId': circle.id,
            'circleName': circle.name,
            'email': '',
            'role': ParticipantRole.viewer.name,
            'inviteStatus': InviteStatus.accepted.name,
            'joinedAt': Timestamp.fromDate(now),
          },
          SetOptions(merge: true),
        );
        continue;
      }

      // A couple circle: every member joins silently, as an editor, so either
      // partner can reshape the plan.
      //
      // **Where the member list comes from matters, and this used to get it
      // wrong.** `circlesProvider` streams circle documents without their
      // `members` subcollection, so `circle.members` is empty in the normal
      // case. The old code fell back to reading the subcollection — which is a
      // second read that can be empty (nobody ever wrote rows) or refused, and
      // when it came back empty the loop below had nobody to iterate and the
      // couple auto-share silently did nothing. That is precisely the "the
      // countdown was created for me but my partner never saw it" symptom.
      //
      // `memberIds` is the denormalised list ON the circle document. It is what
      // every other membership check in this file treats as authoritative, and
      // it is already in hand — no extra read, and no way for it to be empty
      // when the circle has members. So it is the primary source now; the
      // subcollection is only a fallback for a legacy circle that has member
      // rows but an empty `memberIds`.
      final members = <CircleMember>[];
      if (circle.members.isNotEmpty) {
        members.addAll(circle.members);
      } else if (circle.memberIds.isNotEmpty) {
        for (final memberId in circle.memberIds) {
          if (memberId.isEmpty) continue;
          members.add(CircleMember(
            userId: memberId,
            email: '',
            displayName: null,
            photoUrl: null,
          ));
        }
      } else {
        try {
          final memberSnap =
              await _circles.doc(circle.id).collection('members').get();
          members.addAll(
              memberSnap.docs.map((d) => CircleMember.fromMap(d.id, d.data())));
        } catch (error) {
          debugPrint(
            '[datedawn] Could not read members of couple circle ${circle.id}: '
            '$error',
          );
        }
      }
      for (final member in members) {
        if (member.userId == userId) continue;
        invitedUserIds.add(member.userId);
        autoShareMembers.add(member);
      }
    }

    // Commit the countdown and its own participant rows first, and on their own.
    //
    // Invitations and the couple auto-share are deliberately NOT in this batch.
    // A create batch is atomic: one refused write fails all of it, so a rules
    // problem with a follow-up used to make the whole countdown vanish with a
    // bare "Firestore refused the save". The countdown is the thing the person
    // asked for and it is the one write that is always allowed; it must not be
    // hostage to a follow-up.
    await batch.commit();

    // Now add the couple members, then invite, best-effort, one person at a
    // time. By this point the event and the creator's admin row are committed,
    // so `isAdmin()` sees them and both follow-ups are authorised on their own.
    final autoParticipants = await _addCoupleMembers(
      eventId: id,
      inviterId: userId,
      members: autoShareMembers,
      now: now,
    );
    // The partner's participant row alone is not enough. The feed and the read
    // rule both go through `sharedWithMemberIds` on the event, so a partner who
    // is not in that array has a row they can never query their way to — the
    // countdown is created for the creator and silently absent for them.
    //
    // This is unioned from the **intended** members, not from the rows that
    // happened to be written. Keying it off `autoParticipants` meant a refused
    // participant write — the exact failure this is meant to paper over — also
    // skipped the visibility write, so the two failures compounded instead of
    // the second covering the first. The uids come straight from the couple
    // circle's member list, which is authoritative, so the partner is made
    // visible even when their participant row is not yet there: they still get
    // the countdown in their feed, and the row can be added later.
    final coupleMemberIds = <String>{
      ...autoShareMembers.map((m) => m.userId),
      ...autoParticipants.map((p) => p.userId),
    };
    await _addToSharedWithMemberIds(
      eventId: id,
      memberIds: coupleMemberIds.toList(),
    );
    await _inviteAll(
      eventId: id,
      eventTitle: title.trim(),
      inviterId: userId,
      recipients: invitationRecipients,
      invitedUserIds: invitedUserIds,
      now: now,
    );

    return CountdownEvent(
      id: id,
      title: title.trim(),
      description: description.trim(),
      at: at,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      sharedWithCircleIds: validCircleIds,
      // The in-memory copy must match what was actually written, couple members
      // included — the screen that created it reads this object back, and a
      // stale array here is what makes the new countdown look like it was not
      // shared at all until the next full reload.
      sharedWithMemberIds:
          <String>{...sharedMemberIds, ...coupleMemberIds}.toList(),
      participants: [
        Participant(
          userId: userId,
          email: email,
          role: ParticipantRole.admin,
          inviteStatus: InviteStatus.accepted,
          displayName: displayName,
          photoUrl: photoUrl,
          joinedAt: now,
        ),
        ...autoParticipants,
      ],
    );
    // NOTE: this returned object carries the creator's admin row so the new
    // countdown is immediately editable from the screen that created it. The
    // list feed also hydrates participants from Firestore now, so the two agree.
  }

  Future<void> updateEvent({
    required CountdownEvent event,
    required String userId,
    required String title,
    required String description,
    required DateTime at,
  }) async {
    if (!event.canEdit(userId)) {
      throw const DataFailure(
          'Only admins and editors can change this countdown.');
    }
    if (title.trim().isEmpty) {
      throw const DataFailure('Give this countdown a title.');
    }
    if (!at.isAfter(DateTime.now())) {
      throw const DataFailure('Pick a moment still ahead of you.');
    }

    await _events.doc(event.id).update({
      'title': title.trim(),
      'description': description.trim(),
      'at': Timestamp.fromDate(at),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Soft-deletes by stamping `deletedAt`, exactly like the web app: the
  /// document survives so an accidental delete can be recovered, but every read
  /// filters it out.
  Future<void> deleteEvent(
      {required CountdownEvent event, required String userId}) async {
    if (!event.canManage(userId)) {
      throw const DataFailure('Only the owner can delete this countdown.');
    }
    await _events.doc(event.id).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Invites someone by email.
  ///
  /// If an account with that email already exists, a participant row is written
  /// straight away and shows up as pending in the invitee's app. Otherwise the
  /// invitation waits in the `invitations` collection until that email signs up.
  Future<void> inviteByEmail({
    required CountdownEvent event,
    required String inviterId,
    required String email,
    required ParticipantRole role,
    String? inviterEmail,
    String? knownUserId,
    String? displayName,
    String? photoUrl,
  }) async {
    if (!event.canManage(inviterId)) {
      throw const DataFailure('Only the owner can invite people.');
    }
    final target = email.trim().toLowerCase();
    if (target.isEmpty || !target.contains('@')) {
      throw const DataFailure('Enter a valid email address.');
    }
    // You cannot invite yourself: you are already on your own countdown, and a
    // notification addressed to your own account is just noise. Matched on both
    // the email and the uid, because a second account signed in here would slip
    // past an email-only check.
    if (inviterEmail != null && inviterEmail.trim().toLowerCase() == target) {
      throw const DataFailure(cannotInviteSelfMessage);
    }
    if (knownUserId != null && knownUserId == inviterId) {
      throw const DataFailure(cannotInviteSelfMessage);
    }

    // Resolve the email to an account when the caller did not already know the
    // uid. This is what makes the documented behaviour real: an address that
    // already has an account gets a participant row immediately (it appears as
    // pending in their app), while an unknown address waits in `invitations`
    // until that email signs up. Without this the lookup was never called and
    // every invite — even to an existing user — sat unclaimed in `invitations`.
    var targetUserId = knownUserId;
    if (targetUserId == null) {
      final match = await lookupUserByEmail(target);
      final resolvedId = match?['userId'];
      if (resolvedId != null && resolvedId.isNotEmpty) {
        if (resolvedId == inviterId) {
          throw const DataFailure(cannotInviteSelfMessage);
        }
        targetUserId = resolvedId;
        displayName ??= match?['displayName'];
        photoUrl ??= match?['photoUrl'];
      }
    }

    // A block is not advisory: an invite to someone this user has blocked is
    // refused here, by email as well as by uid, so a re-typed address cannot
    // route around the block.
    if (await isBlocked(
      userId: inviterId,
      targetUid: targetUserId ?? '',
      targetEmail: target,
    )) {
      throw const DataFailure(
          'You cannot invite someone you have blocked. Unblock them in '
          'Settings → Blocked people first.');
    }

    // The `invitations` document is written in BOTH branches, and the pending
    // participant row carries its id.
    //
    // The known-account branch used to write only a participant row. That left
    // the invitee with a `pending` row but no `invitations` document, so the
    // accept rule — which authorises the write by checking the invitation the
    // row points at — had nothing to verify and refused the join. Writing the
    // invitation either way also fixes the inbox: it streams `inviteeEmail`,
    // so without a document there was nothing to answer.
    final id = _uuid.v4();
    final now = DateTime.now();
    final invitationBody = {
      'eventId': event.id,
      'invitedBy': inviterId,
      'inviteeEmail': target,
      'role': role.name,
      'status': InviteStatus.pending.name,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
      'eventTitle': event.title,
    };

    if (targetUserId != null) {
      final batch = _db.batch();
      batch.set(_invitations.doc(id), invitationBody);
      batch.set(
        _events.doc(event.id).collection('participants').doc(targetUserId),
        {
          'userId': targetUserId,
          'email': target,
          'role': role.name,
          'inviteStatus': InviteStatus.pending.name,
          'joinedAt': Timestamp.fromDate(now),
          // The back-reference the accept rule resolves against.
          'invitationId': id,
          'invitationEmail': target,
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
        SetOptions(merge: true),
      );
      batch.update(_events.doc(event.id), {
        'sharedWithMemberIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': Timestamp.fromDate(now),
      });
      await batch.commit();

      // Tell the invitee there is something waiting for them. This is the line
      // that makes the inbox useful rather than permanently empty.
      await _notify(
        userId: targetUserId,
        title: 'You were invited to “${event.title}”',
        body: 'Open Invitations to accept or decline.',
        kind: NotificationKind.invitation,
      );
      // Remember them so the invite field suggests this address next time —
      // whoever was invited most recently is offered first.
      await rememberInvitedContacts(
        userId: inviterId,
        contacts: [
          InvitationRecipient(
            userId: targetUserId,
            email: target,
            displayName: displayName,
            photoUrl: photoUrl,
            role: role,
          ),
        ],
      );
      return;
    }

    await _invitations.doc(id).set(invitationBody);
    await rememberInvitedContacts(
      userId: inviterId,
      contacts: [
        InvitationRecipient(
          userId: '',
          email: target,
          displayName: displayName,
          photoUrl: photoUrl,
          role: role,
        ),
      ],
    );
  }

  Future<void> updateParticipantRole({
    required String eventId,
    required String actorId,
    required Participant participant,
    required ParticipantRole role,
  }) async {
    await _events
        .doc(eventId)
        .collection('participants')
        .doc(participant.userId)
        .update({
      'role': role.name,
    });
  }

  /// Drops someone from a countdown entirely.
  ///
  /// Deletes the participant row rather than only downgrading the role: the row
  /// *is* the access. The event document is left alone — this removes a
  /// collaborator, not the countdown.
  Future<void> removeParticipant({
    required String eventId,
    required String actorId,
    required String userId,
  }) async {
    if (userId == actorId) {
      throw const DataFailure(
          'You cannot remove yourself — delete the countdown instead.');
    }
    await _events.doc(eventId).collection('participants').doc(userId).delete();
  }

  /// Live stream of pending invitations addressed to this email.
  Stream<List<Invitation>> watchInvitations(String email) {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return Stream.value(const []);
    return _invitations
        .where('inviteeEmail', isEqualTo: normalised)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Invitation.fromDoc(d.id, d.data()))
            .where((invite) =>
                invite.status == InviteStatus.pending && !invite.isExpired)
            .toList());
  }

  /// Accepts an invitation addressed to the signed-in user and tells the
  /// inviter about it.
  ///
  /// The invitation was matched by the caller's own verified email, so a user
  /// can only ever accept an invite sent to them. The participant row and the
  /// invitation status are written in one batch, and the notification to the
  /// inviter is a separate document so a failure to notify never costs the user
  /// their join.
  Future<void> acceptInvitation({
    required Invitation invitation,
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    await _guardInvitation(invitation);

    // Blocking is a standing refusal, so an invite from someone this user has
    // blocked cannot be accepted even if it was already on screen when the
    // block was made.
    if (invitation.invitedBy.isNotEmpty &&
        await isBlocked(userId: userId, targetUid: invitation.invitedBy)) {
      throw const DataFailure(
          'You have blocked this person. Unblock them in Settings → Blocked '
          'people to accept their invitation.');
    }

    final batch = _db.batch();
    // One write shape for a row that may or may not exist.
    //
    // `merge: true` is essential: an invitee who was previously added by an admin
    // already has a participant row, and a plain `set` would wipe its `role` and
    // demote them. The merge also means a brand-new row is created by this same
    // call, which is the common case for an email invitation the person accepted.
    //
    // `invitationId` is what authorises this write in `firestore.rules`. Rules
    // cannot query a collection, so the id is denormalised onto the row and the
    // rule verifies it with a single `exists()` against the invitation, checking
    // that it is still pending AND addressed to this caller's verified email.
    // Without it the rule had no way to tell a real invitee from any signed-in
    // user who knew an event id.
    batch.set(
      _events.doc(invitation.eventId).collection('participants').doc(userId),
      {
        // The field `watchEvents` queries to discover a shared countdown. A row
        // written without it is unreachable by the invitee's feed, which is why
        // a first-time accept reported success while the countdown never
        // appeared in their list.
        'userId': userId,
        'email': email.toLowerCase(),
        'role': invitation.role.name,
        'inviteStatus': InviteStatus.accepted.name,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
        // Stamped last so it is present on a create. `merge` never removes a
        // field, so this stays accurate on a re-accept after a reopen.
        'invitationId': invitation.id,
        'invitationEmail': invitation.inviteeEmail.toLowerCase(),
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
      SetOptions(merge: true),
    );
    batch.update(_invitations.doc(invitation.id),
        {'status': InviteStatus.accepted.name});
    batch.update(_events.doc(invitation.eventId), {
      'sharedWithMemberIds': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();

    // Best-effort: the user has already joined, so a notify failure is not
    // worth surfacing as an error.
    await _notifyInviter(
      inviterId: invitation.invitedBy,
      eventId: invitation.eventId,
      eventTitle: invitation.eventTitle,
      responderEmail: email,
      responderName: displayName,
      accepted: true,
    );
  }

  Future<void> rejectInvitation(
    Invitation invitation, {
    String? responderEmail,
    String? responderName,
    String? userId,
  }) async {
    // Same guard as accept. Without it a second tap on Decline re-wrote an
    // already-settled invitation, and the failure surfaced as a silent no-op
    // rather than a message explaining that the answer was already given.
    await _guardInvitation(invitation);

    // Settle the participant row as well as the invitation.
    //
    // Only flipping the `invitations` document left the participant row reading
    // `pending` forever, so a person who had clearly declined stayed in the
    // countdown's list as "Viewer · pending" — which is what an owner sees when
    // nobody has answered yet. The two documents describe the same decision and
    // now move together.
    final batch = _db.batch();
    batch.update(_invitations.doc(invitation.id),
        {'status': InviteStatus.declined.name});
    if (userId != null && userId.isNotEmpty) {
      final participant = _events
          .doc(invitation.eventId)
          .collection('participants')
          .doc(userId);
      // The row may not exist yet: someone invited by email has no participant
      // record until they answer, so this is a create in every practical case.
      // The rule allows a self-owned row to be born settled as accepted or
      // declined, so send exactly the fields that shape needs and nothing more
      // — `merge: true` is what lets a pre-existing row keep its role.
      //
      // The `invitationId`/`invitationEmail` pair is the proof the rule checks;
      // see `acceptInvitation`. Decline carries it too, so a row born declined
      // is authorised by exactly the same evidence as one born accepted.
      batch.set(
        participant,
        {
          'userId': userId,
          'email': (responderEmail ?? '').toLowerCase(),
          // `merge` keeps the stored role on an existing row; this value is what
          // the rule sees for a brand-new one, and it is the role the invitation
          // granted rather than one the client chose.
          'role': invitation.role.name,
          'inviteStatus': InviteStatus.declined.name,
          'invitationId': invitation.id,
          'invitationEmail': invitation.inviteeEmail.toLowerCase(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    await _notifyInviter(
      inviterId: invitation.invitedBy,
      eventId: invitation.eventId,
      eventTitle: invitation.eventTitle,
      responderEmail: responderEmail ?? '',
      responderName: responderName,
      accepted: false,
    );
  }

  /// Puts a settled answer back in front of the invitee so they can change it.
  ///
  /// Writes `reopened` on the participant row and moves the invitation back to
  /// `pending`, which is the only shape the `invitations` update rule allows on
  /// this row — so the invitee still has to answer for themselves. An admin
  /// cannot flip someone to `accepted` by asking; only the person can.
  Future<void> reopenInvitation({
    required String eventId,
    required String userId,
    required String inviteeEmail,
    required String eventTitle,
    required String inviterId,
  }) async {
    // A fresh pending invitation is exactly what "ask them again" means, and this
    // is a write rather than an update because the answered document may already
    // have been deleted.
    final invitationId = _uuid.v4();
    final batch = _db.batch();
    // The row must point at the NEW invitation. If it kept citing the old,
    // settled one, the invitee's next accept would be refused by the rule —
    // `invitationAuthorisesRow` requires a `pending` invitation addressed to
    // them, and the previous document is no longer that.
    batch.set(
      _events.doc(eventId).collection('participants').doc(userId),
      {
        'userId': userId,
        'inviteStatus': InviteStatus.reopened.name,
        'invitationId': invitationId,
        'invitationEmail': inviteeEmail.toLowerCase(),
      },
      SetOptions(merge: true),
    );
    batch.set(_invitations.doc(invitationId), {
      'eventId': eventId,
      'invitedBy': inviterId,
      'inviteeEmail': inviteeEmail.toLowerCase(),
      'role': ParticipantRole.viewer.name,
      'status': InviteStatus.pending.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'eventTitle': eventTitle,
    });
    await batch.commit();

    await _notify(
      userId: userId,
      title: 'You were invited to “$eventTitle” again',
      body:
          'The invitation is open again — accept or decline whenever you like.',
      kind: NotificationKind.invitation,
    );
  }

  /// Refuses an invitation that has already been answered.
  ///
  /// **Why this reads the live document instead of trusting the argument.**
  /// `_guardInvitation(invitation)` used to check `invitation.status`, but that
  /// object is a *snapshot* the caller captured when its widget was built. It
  /// says `pending` forever, however many times it is re-submitted, so the
  /// guard never fired and a settled invitation could be answered again and
  /// again. Comparing a stale copy of the state against itself can never detect
  /// that the state has moved on.
  ///
  /// This re-reads the document, which is the only authority on whether an
  /// answer is still open.
  Future<void> _guardInvitation(Invitation invitation) async {
    if (invitation.isExpired) {
      throw const DataFailure('That invitation has expired.');
    }
    // Fast path: the caller already knows it is settled.
    if (invitation.status != InviteStatus.pending) {
      throw const DataFailure('That invitation has already been answered.');
    }

    final doc = await _invitations.doc(invitation.id).get();
    final live = doc.data();
    if (!doc.exists || live == null) {
      throw const DataFailure('That invitation no longer exists.');
    }
    if (live['status'] != InviteStatus.pending.name) {
      throw const DataFailure('That invitation has already been answered.');
    }
  }

  /// Whether [userId] still has a decision to make on [eventId].
  ///
  /// Read from the participant row rather than the invitation, because that is
  /// the document the invitations list and the participant list both agree on,
  /// and it survives the invitation being deleted.
  bool participantAwaitsAnswer(CountdownEvent event, String userId) {
    for (final participant in event.participants) {
      if (participant.userId == userId) {
        return participant.inviteStatus.isAwaitingAnswer;
      }
    }
    return false;
  }

  /// Everyone in the given circles except [excludingUserId], as people who can
  /// be invited to a countdown.
  ///
  /// Hydrates each circle's `members` subcollection on demand: the circle
  /// documents `circlesProvider` streams do not carry it, so the in-memory
  /// `circle.members` is usually empty and iterating it would invite nobody.
  Future<List<InvitationRecipient>> circleInvitees({
    required Iterable<String> circleIds,
    required String excludingUserId,
  }) async {
    final recipients = <String, InvitationRecipient>{};
    for (final circleId in circleIds) {
      final snap = await _circles.doc(circleId).collection('members').get();
      for (final doc in snap.docs) {
        if (doc.id == excludingUserId) continue;
        final member = CircleMember.fromMap(doc.id, doc.data());
        if (member.email.isEmpty) continue;
        recipients[member.userId] = InvitationRecipient(
          userId: member.userId,
          email: member.email,
          displayName: member.displayName,
          photoUrl: member.photoUrl,
        );
      }
    }
    return recipients.values.toList();
  }

  /// Refuses a circle invitation that has already been answered.
  ///
  /// Reads the stored document rather than the caller's snapshot, for the same
  /// reason as [_guardInvitation]: a snapshot captured at build time always
  /// says `pending`, so it cannot detect that the invitation has moved on.
  Future<void> _guardCircleInvitation(CircleInvitation invitation) async {
    if (invitation.status != InviteStatus.pending) {
      throw const DataFailure('That invitation has already been answered.');
    }
    final doc = await _circleInvitations.doc(invitation.id).get();
    final live = doc.data();
    if (!doc.exists || live == null) {
      throw const DataFailure('That invitation no longer exists.');
    }
    if (live['status'] != InviteStatus.pending.name) {
      throw const DataFailure('That invitation has already been answered.');
    }
  }

  /// Every member uid of every circle in [circleIds].
  ///
  /// `circlesProvider` streams circle documents without their `members`
  /// subcollection, so `circle.members` is usually empty; each one is hydrated
  /// from the subcollection on demand. The result is denormalised onto the event
  /// as `sharedWithMemberIds`, which is what lets the visibility rule be a plain
  /// array check the client can query against.
  Future<Set<String>> _circleMemberIds({
    required List<String> circleIds,
    required List<Circle> circles,
  }) async {
    final memberIds = <String>{};
    for (final circleId in circleIds) {
      final circle = circles.where((c) => c.id == circleId).firstOrNull;
      if (circle == null) continue;
      // `memberIds` is the denormalised list on the circle document itself and
      // is maintained on join/leave, so it is authoritative and needs no extra
      // read. Fall back to the subcollection only if it is somehow empty.
      if (circle.memberIds.isNotEmpty) {
        memberIds.addAll(circle.memberIds);
        continue;
      }
      try {
        final snap = await _circles.doc(circleId).collection('members').get();
        memberIds.addAll(snap.docs.map((d) => d.id));
      } catch (error) {
        // Best-effort: a circle whose members cannot be read still shares the
        // event with the circles that could be read.
        debugPrint('[datedawn] Could not read members of $circleId: $error');
      }
    }
    return memberIds;
  }

  /// Writes the accepted editor participant rows for a couple circle's members.
  ///
  /// Runs **after** the create batch has committed, deliberately. Adding someone
  /// else's participant row needs `isAdmin(eventId)` or `isOwner(...)` in
  /// `firestore.rules`, and both are plain `get()` calls that resolve against
  /// the database as it was when the request started — so inside the create
  /// batch they cannot see the admin row that same batch is writing, and the
  /// write is refused. Because a batch is atomic, that refusal took the whole
  /// countdown with it: the partner got nothing and the creator lost the event.
  ///
  /// Now that the event and the creator's admin row are committed, the rule is
  /// satisfied on its own. This is best-effort for the same reason invitations
  /// are: the countdown is already saved, so a failure here degrades to "created
  /// but the partner was not added" rather than losing the countdown.
  ///
  /// Returns the rows it managed to write, so the caller's in-memory copy of the
  /// new countdown matches what is in Firestore.
  Future<List<Participant>> _addCoupleMembers({
    required String eventId,
    required String inviterId,
    required List<CircleMember> members,
    required DateTime now,
  }) async {
    if (members.isEmpty) return const [];
    final written = <Participant>[];
    final batch = _db.batch();
    for (final member in members) {
      if (member.userId.isEmpty || member.userId == inviterId) continue;
      batch.set(
        _events.doc(eventId).collection('participants').doc(member.userId),
        {
          // The field `watchEvents` queries to discover a shared countdown.
          // Without it the partner's feed never matched this row, so the
          // countdown existed but never appeared for them.
          'userId': member.userId,
          'email': member.email,
          'role': ParticipantRole.editor.name,
          'inviteStatus': InviteStatus.accepted.name,
          'joinedAt': Timestamp.fromDate(now),
          if (member.displayName != null) 'displayName': member.displayName,
          if (member.photoUrl != null) 'photoUrl': member.photoUrl,
        },
        SetOptions(merge: true),
      );
      written.add(
        Participant(
          userId: member.userId,
          email: member.email,
          role: ParticipantRole.editor,
          inviteStatus: InviteStatus.accepted,
          displayName: member.displayName,
          photoUrl: member.photoUrl,
          joinedAt: now,
        ),
      );
    }
    if (written.isEmpty) return const [];
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      // Logged loudly, not swallowed. This is the couple auto-share: the whole
      // promise of the feature is that the partner gets the countdown with no
      // action of their own, so a refusal here is not a cosmetic failure — it
      // is the feature not working. `permission-denied` means the deployed
      // rules do not match this client.
      debugPrint(
        '[datedawn] Couple auto-share FAILED for event $eventId '
        '(${error.code}). The countdown was created but the partner was NOT '
        'added. If this is permission-denied, deploy the rules: '
        'firebase deploy --only firestore:rules,firestore:indexes',
      );
      return const [];
    } catch (error) {
      // Offline, or a transient failure. The countdown still exists and the
      // creator can share it from the countdown screen.
      debugPrint('[datedawn] Could not add couple members to $eventId: $error');
      return const [];
    }
    return written;
  }

  /// Unions [memberIds] into `sharedWithMemberIds` on the countdown [eventId].
  ///
  /// The couple auto-share writes participant rows, but the feed query and the
  /// read rule both key off this array, so the rows are invisible without it.
  /// `arrayUnion` (not a whole-array rewrite) because this runs concurrently
  /// with nothing else on a fresh event but must stay idempotent when it is
  /// called again after a re-share.
  ///
  /// Best-effort, like the auto-share it follows: the countdown is already
  /// committed, and a failure here degrades to the partner seeing it only after
  /// they open it from a notification, not to a broken create.
  Future<void> _addToSharedWithMemberIds({
    required String eventId,
    required List<String> memberIds,
  }) async {
    final ids = memberIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;
    try {
      await _events.doc(eventId).update({
        'sharedWithMemberIds': FieldValue.arrayUnion(ids),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (error) {
      debugPrint(
        '[datedawn] Could not add couple members to sharedWithMemberIds for '
        '$eventId (${error.code}). The partner may not see the countdown until '
        'it is re-shared. If this is permission-denied, deploy the rules: '
        'firebase deploy --only firestore:rules',
      );
    } catch (error) {
      debugPrint(
        '[datedawn] Could not update sharedWithMemberIds for $eventId: $error',
      );
    }
  }

  /// Writes the pending participant rows and `invitations` documents for a
  /// freshly created countdown.
  ///
  /// Best-effort by design. The countdown is already committed by the time this
  /// runs, so a refusal here must not turn a successful create into a failure —
  /// it degrades to "created, but nobody was told", which is recoverable by
  /// inviting them from the countdown afterwards.
  Future<void> _inviteAll({
    required String eventId,
    required String eventTitle,
    required String inviterId,
    required List<InvitationRecipient> recipients,
    required Iterable<String> invitedUserIds,
    required DateTime now,
  }) async {
    final nowStamp = Timestamp.fromDate(now);
    final expiresStamp = Timestamp.fromDate(now.add(const Duration(days: 30)));
    final seen = <String>{inviterId};

    Future<void> invite({
      required String targetUserId,
      required String targetEmail,
      String? targetDisplayName,
      String? targetPhotoUrl,
      required ParticipantRole role,
    }) async {
      if (targetEmail.isEmpty) return;
      if (!seen.add(targetUserId)) return;
      try {
        final batch = _db.batch();
        // The invitation id is generated up front so the participant row can
        // carry it. That back-reference is what `firestore.rules` resolves to
        // authorise the later accept — see `acceptInvitation`.
        final invitationId = _uuid.v4();
        batch.set(
          _events.doc(eventId).collection('participants').doc(targetUserId),
          {
            'userId': targetUserId,
            'email': targetEmail.toLowerCase(),
            'role': role.name,
            'inviteStatus': InviteStatus.pending.name,
            'joinedAt': nowStamp,
            'invitationId': invitationId,
            'invitationEmail': targetEmail.toLowerCase(),
            if (targetDisplayName != null) 'displayName': targetDisplayName,
            if (targetPhotoUrl != null) 'photoUrl': targetPhotoUrl,
          },
          SetOptions(merge: true),
        );
        // The `invitations` document is what the invitee's inbox actually
        // streams — `invitationsProvider` queries `inviteeEmail`, not the
        // participant rows. Without it there is nothing to accept.
        batch.set(_invitations.doc(invitationId), {
          'eventId': eventId,
          'invitedBy': inviterId,
          'inviteeEmail': targetEmail.toLowerCase(),
          'role': role.name,
          'status': InviteStatus.pending.name,
          'createdAt': nowStamp,
          'expiresAt': expiresStamp,
          'eventTitle': eventTitle,
        });
        batch.update(_events.doc(eventId), {
          'sharedWithMemberIds': FieldValue.arrayUnion([targetUserId]),
          'updatedAt': nowStamp,
        });
        await batch.commit();

        await _notify(
          userId: targetUserId,
          title: 'You were invited to “$eventTitle”',
          body: 'Open Invitations to accept or decline.',
          kind: NotificationKind.invitation,
        );
      } catch (error) {
        // One person's invite failing must not stop the others, and must never
        // surface as a failed create.
        debugPrint('[datedawn] Could not invite $targetEmail: $error');
      }
    }

    for (final recipient in recipients) {
      await invite(
        targetUserId: recipient.userId,
        targetEmail: recipient.email,
        targetDisplayName: recipient.displayName,
        targetPhotoUrl: recipient.photoUrl,
        role: recipient.role,
      );
    }
    for (final targetUserId in invitedUserIds) {
      final profile = await lookupUserById(targetUserId);
      final targetEmail = profile?['email'];
      // An invitation is addressed by email, so a uid with none on file cannot
      // be invited this way — the caller should pass a `recipient` instead.
      if (targetEmail == null || targetEmail.isEmpty) continue;
      await invite(
        targetUserId: targetUserId,
        targetEmail: targetEmail,
        targetDisplayName: profile?['displayName'],
        targetPhotoUrl: profile?['photoUrl'],
        role: ParticipantRole.viewer,
      );
    }

    // Remember everyone this countdown invited, so the invite field suggests
    // them next time without the address being typed out again.
    await rememberInvitedContacts(
      userId: inviterId,
      contacts: recipients,
    );
  }

  /// Re-denormalises [sharedWithMemberIds] onto every countdown shared with a
  /// circle whose membership just changed.
  ///
  /// Called after leaving or being removed from a circle. The array on the event
  /// is what the visibility rule reads, so a stale one would keep serving
  /// countdowns to someone who is no longer in the circle.
  ///
  /// **Ordering is load-bearing.** The query below reaches the affected
  /// countdowns through `sharedWithMemberIds arrayContains <actor>`, which only
  /// works while the actor is *still in that array*. Every caller therefore
  /// prunes the array first and only then removes the actor from the circle's
  /// `memberIds` — or, for a leave/remove, is querying with a uid that is still
  /// present on the events. Reorder either one (delete the participant row
  /// first, resync second) and this silently returns nothing: the same class of
  /// bug as the join path, where the actor was absent from the array and the
  /// query found nothing.
  ///
  /// **This is not called on join.** A joiner is not in the array yet, so this
  /// query cannot find their events; the seeding is done at invite time by
  /// [_seedInviteeIntoCircleShares], which runs as the owner. See that method.
  ///
  /// Best-effort and chunked: a batch caps at 500 writes, and the caller's own
  /// action has already committed by the time this runs.
  Future<void> _resyncCircleShares(String circleId,
      {required String actorId}) async {
    try {
      final circleDoc = await _circles.doc(circleId).get();
      final raw = circleDoc.data()?['memberIds'];
      if (raw is! List) return;
      final memberIds = raw.whereType<String>().toList();

      // Queried through the caller's own membership (`sharedWithMemberIds`
      // contains them) rather than by circle id, for the same reason the feed
      // is: the rule can prove a field comparison for a query, but not a
      // cross-collection `get()`. An owner who just removed themselves is not a
      // member any more, so the owner falls back to `sharedWithCircleIds`.
      final shared = memberIds.contains(actorId)
          ? await _events
              .where('sharedWithMemberIds', arrayContains: actorId)
              .get()
          : await _events
              .where('sharedWithCircleIds', arrayContains: circleId)
              .get();
      final targets = shared.docs
          .where((doc) =>
              (doc.data()['sharedWithCircleIds'] as List?)
                  ?.contains(circleId) ==
              true)
          .toList();
      if (targets.isEmpty) return;

      for (var i = 0; i < targets.length; i += 400) {
        final end = i + 400 > targets.length ? targets.length : i + 400;
        final batch = _db.batch();
        for (final doc in targets.sublist(i, end)) {
          batch.update(doc.reference, {
            'sharedWithMemberIds': memberIds,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
        await batch.commit();
      }
    } catch (error) {
      // The membership change is the user's action and has already committed.
      debugPrint('[datedawn] Could not resync shares for $circleId: $error');
    }
  }

  /// Leaves a one-way note telling the inviter what the invitee chose.
  Future<void> _notifyInviter({
    required String inviterId,
    required String eventId,
    required String eventTitle,
    required String responderEmail,
    required bool accepted,
    String? responderName,
  }) async {
    // Inviting yourself is possible when the same person owns two accounts;
    // no point notifying them about their own action.
    if (inviterId.isEmpty) return;

    final title = eventTitle.isEmpty ? 'your countdown' : '“$eventTitle”';
    final who = (responderName?.trim().isNotEmpty ?? false)
        ? responderName!
        : responderEmail;

    try {
      await _responses.doc(_uuid.v4()).set({
        'recipientId': inviterId,
        'eventId': eventId,
        'eventTitle': eventTitle.isEmpty ? 'your countdown' : eventTitle,
        'responderEmail': responderEmail.toLowerCase(),
        if (responderName != null) 'responderName': responderName,
        'accepted': accepted,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'read': false,
      });
    } catch (_) {
      // The response document is a courtesy; never fail the user's action on it.
    }

    // Mirror the same event into the invitee's inbox, which is the feed the
    // Notifications screen streams live. Without this the inbox stayed
    // empty — the second database looked broken because nothing ever wrote to
    // it.
    await _notify(
      userId: inviterId,
      title: accepted ? '$who joined $title' : '$who declined $title',
      body: accepted
          ? 'They can now follow this countdown.'
          : 'They chose not to follow this countdown.',
      kind: NotificationKind.invitation,
    );
  }

  /// Sends one inbox notification, swallowing any failure.
  ///
  /// Notifications are a courtesy on top of a write that has already
  /// succeeded, so a failure here must never surface as an error to the user.
  Future<void> _notify({
    required String userId,
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.system,
  }) async {
    final sink = notificationSink;
    if (sink == null || userId.isEmpty) return;
    try {
      await sink(userId: userId, title: title, body: body, kind: kind);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Live stream of the answers to invitations this user sent.
  Stream<List<InvitationResponse>> watchResponses(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _responses
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => InvitationResponse.fromDoc(d.id, d.data()))
          .toList()
        // Newest first, so an unread answer is at the top of the list.
        ..sort((a, b) => b.respondedAt.compareTo(a.respondedAt));
      return items;
    });
  }

  Future<void> markResponseRead(String responseId) async {
    await _responses.doc(responseId).update({'read': true});
  }

  /// Removes one answer from the inviter's log.
  ///
  /// A response is a one-way courtesy note, so clearing it is a real delete
  /// rather than a hidden flag — nothing else references it.
  Future<void> deleteResponse(String responseId) async {
    if (responseId.isEmpty) return;
    await _responses.doc(responseId).delete();
  }

  // ---------------------------------------------------------------------------
  // Circles
  // ---------------------------------------------------------------------------

  /// Live stream of the circles this user belongs to.
  Stream<List<Circle>> watchCircles(String userId) {
    return _circles.where('memberIds', arrayContains: userId).snapshots().map(
        (snap) => snap.docs.map((d) => Circle.fromDoc(d.id, d.data())).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  /// Live stream of a circle's members, hydrated from its `members`
  /// subcollection so the UI can show names and avatars.
  Stream<List<CircleMember>> watchCircleMembers(String circleId) {
    return _circles.doc(circleId).collection('members').snapshots().map(
        (snap) => snap.docs
            .map((d) => CircleMember.fromMap(d.id, d.data()))
            .toList());
  }

  /// Creates a circle. The owner is written as a member in the same batch, so
  /// the circle always has at least one person who can see it.
  Future<Circle> createCircle({
    required String ownerId,
    required String ownerEmail,
    required String name,
    String? ownerName,
    String? ownerPhotoUrl,
    String? emoji,
    bool isCouple = false,
  }) async {
    if (name.trim().isEmpty) {
      throw const DataFailure('Give this circle a name.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final batch = _db.batch();

    batch.set(_circles.doc(id), {
      'name': name.trim(),
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(now),
      'isCouple': isCouple,
      if (emoji != null) 'emoji': emoji,
      'memberIds': [ownerId],
    });
    batch.set(_circles.doc(id).collection('members').doc(ownerId), {
      'email': ownerEmail.toLowerCase(),
      'isOwner': true,
      'joinedAt': Timestamp.fromDate(now),
      if (ownerName != null) 'displayName': ownerName,
      if (ownerPhotoUrl != null) 'photoUrl': ownerPhotoUrl,
    });
    await batch.commit();

    return Circle(
      id: id,
      name: name.trim(),
      ownerId: ownerId,
      createdAt: now,
      emoji: emoji,
      isCouple: isCouple,
      memberIds: [ownerId],
    );
  }

  /// Invites an email into a circle.
  ///
  /// Standard circles always require the invitee to accept. Existing accounts
  /// invited to a couple circle are added immediately; an unknown email gets a
  /// pending invite which is joined automatically when that account signs in.
  Future<void> inviteToCircle({
    required Circle circle,
    required String inviterId,
    required String email,
    String? inviterEmail,
    String? inviterName,
    ParticipantRole role = ParticipantRole.editor,
  }) async {
    if (!circle.isOwner(inviterId)) {
      throw const DataFailure('Only the circle owner can invite people.');
    }
    final target = email.trim().toLowerCase();
    if (target.isEmpty || !target.contains('@')) {
      throw const DataFailure('Enter a valid email address.');
    }
    // You cannot invite yourself into your own circle: the owner is already a
    // member, and the invitation would notify your own account. Checked on the
    // email (what is typed, normalised so casing cannot slip past).
    if (inviterEmail != null && inviterEmail.trim().toLowerCase() == target) {
      throw const DataFailure(cannotInviteSelfMessage);
    }

    // Hydrate the member list if the caller only had the circle document
    // (`circlesProvider` streams it without the `members` subcollection), so
    // both the duplicate check and the self-check below actually have rows to
    // compare against instead of silently passing.
    var members = circle.members;
    if (members.isEmpty) {
      final snap = await _circles.doc(circle.id).collection('members').get();
      members =
          snap.docs.map((d) => CircleMember.fromMap(d.id, d.data())).toList();
    }
    if (members.any((m) => m.userId == inviterId && m.email == target)) {
      throw const DataFailure(cannotInviteSelfMessage);
    }
    if (members.any((m) => m.email == target)) {
      throw DataFailure('$target is already in “${circle.name}”.');
    }

    final match = await lookupUserByEmail(target);
    final inviteeId = match?['userId'];
    if (inviteeId == inviterId) {
      throw const DataFailure(cannotInviteSelfMessage);
    }
    if (inviteeId != null && circle.memberIds.contains(inviteeId)) {
      throw DataFailure('$target is already in “${circle.name}”.');
    }

    final recentContact = InvitationRecipient(
      userId: inviteeId ?? '',
      email: target,
      displayName: match?['displayName'],
      photoUrl: match?['photoUrl'],
    );

    // A couple relationship is the app's explicit auto-sharing choice. When
    // the target already has an account, the owner adds them directly rather
    // than creating an invitation they would have to accept.
    if (circle.isCouple && inviteeId != null && inviteeId.isNotEmpty) {
      final now = DateTime.now();
      final batch = _db.batch();
      batch.set(
        _circles.doc(circle.id).collection('members').doc(inviteeId),
        {
          'email': target,
          'isOwner': false,
          'joinedAt': Timestamp.fromDate(now),
          if (match?['displayName'] != null)
            'displayName': match!['displayName'],
          if (match?['photoUrl'] != null) 'photoUrl': match!['photoUrl'],
        },
      );
      batch.update(_circles.doc(circle.id), {
        'memberIds': FieldValue.arrayUnion([inviteeId]),
      });
      await batch.commit();

      await rememberInvitedContacts(
        userId: inviterId,
        contacts: [recentContact],
      );
      await _seedInviteeIntoCircleShares(
        circleId: circle.id,
        inviteeId: inviteeId,
        actorId: inviterId,
      );
      await _notify(
        userId: inviteeId,
        title: '${inviterName ?? 'Someone'} added you to “${circle.name}”',
        body: 'Your countdowns shared with this couple circle are now visible '
            'to each other.',
        kind: NotificationKind.circle,
      );
      return;
    }

    await _circleInvitations.doc(_uuid.v4()).set({
      'circleId': circle.id,
      'invitedBy': inviterId,
      if (inviterName != null) 'invitedByName': inviterName,
      'inviteeEmail': target,
      'circleName': circle.name,
      'isCouple': circle.isCouple,
      // `role` is reserved for a future per-circle permission model; today every
      // member of a circle can create and see its countdowns.
      'role': role.name,
      'status': InviteStatus.pending.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    // Record after the invitation is committed. For an unregistered address
    // the email remains the stable fallback key.
    await rememberInvitedContacts(
      userId: inviterId,
      contacts: [recentContact],
    );

    // If the invitee already has an account, seed their uid into any countdowns
    // already shared with a standard circle before they accept.
    if (inviteeId != null && inviteeId.isNotEmpty && inviteeId != inviterId) {
      // **The join-time resync cannot do this, so it happens here.**
      //
      // `_resyncCircleShares` finds the affected countdowns by querying
      // `sharedWithMemberIds arrayContains <actor>`. That works for leave and
      // remove, because the leaver is still in the array at the moment of the
      // query — pruning is what removes them. It cannot work for a join: the
      // joiner is not in the array yet, that is precisely what the resync exists
      // to add, so the query returns nothing and no event is ever updated.
      //
      // The joiner also cannot do it themselves: writing to `events/{id}` needs
      // `isOwner` or `isEditor`, and a brand-new member is neither. The owner
      // IS authorized, and is the one person guaranteed to be online at the
      // moment the membership is about to change — so the work happens at invite
      // time, on the owner's client, before the invitee ever answers.
      //
      // Cost: one write per countdown already shared with the circle. A circle
      // with no countdowns yet — which is the common case, and the reason this
      // gap went unnoticed — does nothing here at all.
      await _seedInviteeIntoCircleShares(
        circleId: circle.id,
        inviteeId: inviteeId,
        actorId: inviterId,
      );

      await _notify(
        userId: inviteeId,
        title: 'You were invited to “${circle.name}”',
        body: 'Open Invitations to accept or decline.',
        kind: NotificationKind.circle,
      );
    }
  }

  /// Adds [inviteeId] to `sharedWithMemberIds` on every countdown shared with
  /// [circleId].
  ///
  /// Run by the circle **owner** at invite time. The uid is seeded while the
  /// invitation is still pending, so the invitee is already covered by the
  /// visibility rule on the day they accept — and `_resyncCircleShares` can
  /// then find those events, because by that point the joiner IS in the array.
  ///
  /// Querying by `sharedWithCircleIds` rather than `sharedWithMemberIds` is
  /// deliberate here: this runs as the owner, who is in the array for every
  /// event they shared, but an event shared by a co-owner would be missed by an
  /// `arrayContains: actorId` query. The circle id matches all of them.
  ///
  /// Best-effort: the invitation itself is already written and must not fail
  /// because this fan-out did. A miss degrades to the pre-existing behaviour
  /// (the invitee sees countdowns shared *after* they joined), not to a broken
  /// invite.
  Future<void> _seedInviteeIntoCircleShares({
    required String circleId,
    required String inviteeId,
    required String actorId,
  }) async {
    try {
      final shared = await _events
          .where('sharedWithCircleIds', arrayContains: circleId)
          .get();
      if (shared.docs.isEmpty) return;

      for (var i = 0; i < shared.docs.length; i += 400) {
        final end = i + 400 > shared.docs.length ? shared.docs.length : i + 400;
        final batch = _db.batch();
        for (final doc in shared.docs.sublist(i, end)) {
          // `arrayUnion` rather than a whole-array rewrite: this is one uid
          // being added, and a concurrent membership change elsewhere must not
          // be clobbered by a stale list read here.
          batch.update(doc.reference, {
            'sharedWithMemberIds': FieldValue.arrayUnion([inviteeId]),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
        await batch.commit();
      }
    } on FirebaseException catch (error) {
      debugPrint(
        '[datedawn] Could not seed $inviteeId into circle $circleId shares '
        '(${error.code}). Countdowns shared with this circle BEFORE the '
        'invitation will not be visible to them until they are re-shared.',
      );
    } catch (error) {
      debugPrint(
          '[datedawn] Could not seed circle shares for $circleId: $error');
    }
  }

  /// Live stream of pending circle invitations addressed to this email.
  Stream<List<CircleInvitation>> watchCircleInvitations(String email) {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return Stream.value(const []);
    return _circleInvitations
        .where('inviteeEmail', isEqualTo: normalised)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CircleInvitation.fromDoc(d.id, d.data()))
            .where((invite) =>
                invite.status == InviteStatus.pending && !invite.isExpired)
            .toList());
  }

  /// Joins the circle an invitation points at.
  ///
  /// Writes the member row, appends the uid to the circle's denormalised
  /// `memberIds` (so security rules can check membership in one read), and
  /// flips the invitation to accepted. All three in one batch: a partial write
  /// would leave someone invited but not a member.
  Future<void> acceptCircleInvitation({
    required CircleInvitation invitation,
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    if (invitation.isExpired) {
      throw const DataFailure('That invitation has expired.');
    }
    // Same live-document check as the countdown invitation: the object the
    // caller holds is a build-time snapshot that always reads `pending`, so
    // only the stored document can say whether an answer is still open. Without
    // this, a settled circle invitation was re-committed on every rebuild.
    await _guardCircleInvitation(invitation);

    final batch = _db.batch();
    batch.set(
      _circles.doc(invitation.circleId).collection('members').doc(userId),
      {
        'email': email.toLowerCase(),
        'isOwner': false,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
      SetOptions(merge: true),
    );
    batch.update(_circles.doc(invitation.circleId), {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(_circleInvitations.doc(invitation.id),
        {'status': InviteStatus.accepted.name});
    await batch.commit();

    // Deliberately NO resync here.
    //
    // The invitee's uid was already seeded into `sharedWithMemberIds` on every
    // countdown shared with this circle, back when the owner sent the
    // invitation (see `_seedInviteeIntoCircleShares`). Doing it here instead
    // could not work: `_resyncCircleShares` reaches the affected countdowns
    // through `sharedWithMemberIds arrayContains <joiner>`, and the joiner is
    // not in that array yet — that is the whole thing the resync would be
    // adding. The query would return nothing, no event would be updated, and
    // the new member would see only countdowns shared after they joined.
    //
    // The joiner also cannot do this write at all: it needs `isOwner` or
    // `isEditor` on the event, and a brand-new member is neither.

    // Tell the person who invited them. Best-effort: they have already joined.
    if (invitation.invitedBy.isNotEmpty && invitation.invitedBy != userId) {
      final who =
          (displayName?.trim().isNotEmpty ?? false) ? displayName! : email;
      await _notify(
        userId: invitation.invitedBy,
        title: invitation.isCouple
            ? '$who accepted your partner invitation'
            : '$who joined “${invitation.circleName}”',
        body: invitation.isCouple
            ? 'Your countdowns now share with each other automatically.'
            : 'You can now share countdowns with this circle in one tap.',
        kind: NotificationKind.circle,
      );
    }
  }

  /// Declines a circle invitation and tells the inviter.
  ///
  /// The notification is the point of this method being more than a status
  /// flip: the person who sent the invitation had no way to learn it was turned
  /// down, so a couple invitation in particular sat in limbo with the sender
  /// assuming it was still pending. It is best-effort — the status write is the
  /// user's actual action, and it must not fail because a courtesy note did.
  Future<void> rejectCircleInvitation(
    CircleInvitation invitation, {
    String? responderEmail,
    String? responderName,
    String? userId,
  }) async {
    await _guardCircleInvitation(invitation);

    await _circleInvitations
        .doc(invitation.id)
        .update({'status': InviteStatus.rejected.name});

    if (invitation.invitedBy.isEmpty || invitation.invitedBy == userId) return;

    final who = (responderName?.trim().isNotEmpty ?? false)
        ? responderName!
        : (responderEmail ?? 'They');

    await _notify(
      userId: invitation.invitedBy,
      title: invitation.isCouple
          ? '$who declined your partner invitation'
          : '$who declined your invitation to “${invitation.circleName}”',
      body: invitation.isCouple
          ? 'Nothing was shared. Their countdowns stay private.'
          : 'They are not part of this circle.',
      kind: NotificationKind.circle,
    );
  }

  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.delete(_circles.doc(circleId).collection('members').doc(userId));
    batch.update(_circles.doc(circleId), {
      'memberIds': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();

    // Drop the uid from every countdown's denormalised member list, or they
    // keep being served to someone who has left the circle.
    await _resyncCircleShares(circleId, actorId: userId);
  }

  /// Removes someone else from a circle. Owner only.
  ///
  /// The mirror of [leaveCircle] performed on another person's behalf, so it
  /// deletes their member row and pulls their uid out of `memberIds` in one
  /// batch — a partial write would leave them able to see the circle through
  /// the denormalised list while holding no member row.
  ///
  /// The owner cannot remove themselves this way; that is what deleting the
  /// circle is for, and a circle with no owner would be unmanageable.
  Future<void> removeCircleMember({
    required String circleId,
    required String ownerId,
    required String memberId,
  }) async {
    if (memberId == ownerId) {
      throw const DataFailure(
          'You cannot remove yourself — delete the circle instead.');
    }

    final circleDoc = await _circles.doc(circleId).get();
    final data = circleDoc.data();
    if (data == null) {
      throw const DataFailure('That circle no longer exists.');
    }
    // Checked here as well as in the rules so the user gets a sentence rather
    // than a bare permission error.
    if (data['ownerId'] != ownerId) {
      throw const DataFailure('Only the circle owner can remove people.');
    }

    final batch = _db.batch();
    batch.delete(_circles.doc(circleId).collection('members').doc(memberId));
    batch.update(_circles.doc(circleId), {
      'memberIds': FieldValue.arrayRemove([memberId]),
    });
    await batch.commit();

    // Same reason as `leaveCircle`: the removed person must stop being served
    // countdowns through the denormalised list.
    await _resyncCircleShares(circleId, actorId: ownerId);
  }

  // ---------------------------------------------------------------------
  // Blocking another person
  // ---------------------------------------------------------------------
  //
  // Google Play's user-generated-content policy requires apps with 1:1
  // interaction (this one has invitations and notes) to offer in-app blocking.
  // "Block" here means what a person expects: the connection is cut, not just
  // hidden.

  /// Live stream of the people this user has blocked, newest first.
  Stream<List<BlockedUser>> watchBlockedUsers(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _blocked(userId).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => BlockedUser.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        final left = a.blockedAt;
        final right = b.blockedAt;
        if (left == null && right == null) return a.label.compareTo(b.label);
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
      return list;
    });
  }

  /// Blocks [targetUid] and severs every tie between the two accounts.
  ///
  /// A row in `users/{me}/blocked` alone would be a setting, not a block: the
  /// blocked person could still see and edit a shared countdown, still be a
  /// member of a shared circle, and still have a pending invitation sitting in
  /// the inbox. So this does four things, each best-effort and each logged
  /// rather than thrown, because a refusal on one (a countdown this user can
  /// read but not edit) must not leave the block half-applied:
  ///
  /// 1. Writes the block row first. It is what the UI reads, and everything
  ///    below is clean-up of a block that already exists.
  /// 2. Removes them from every shared countdown and deletes any pending
  ///    invitation between the two of you, in either direction.
  /// 3. If the two of you share a circle, leaves it — a circle is the only other
  ///    standing channel between two accounts, and its rules only let a member
  ///    remove themselves (the owner can remove others, but the owner may not be
  ///    the one blocking).
  /// 4. Forgets them from recents, so they are not suggested as an invitee.
  ///
  /// The blocked person is never notified and cannot tell they were blocked.
  Future<void> blockUser({
    required String userId,
    required String targetUid,
    String targetEmail = '',
    String? targetDisplayName,
    String? targetPhotoUrl,
  }) async {
    if (targetUid.isEmpty) {
      throw const DataFailure('That account could not be identified.');
    }
    if (targetUid == userId) {
      throw const DataFailure('You cannot block yourself.');
    }

    final email = targetEmail.trim().toLowerCase();

    // 1. The block itself. Written with `set`, so blocking twice is harmless.
    await _blocked(userId).doc(targetUid).set({
      'email': email,
      if (targetDisplayName != null && targetDisplayName.trim().isNotEmpty)
        'displayName': targetDisplayName.trim(),
      if (targetPhotoUrl != null && targetPhotoUrl.isNotEmpty)
        'photoUrl': targetPhotoUrl,
      'blockedAt': Timestamp.fromDate(DateTime.now()),
    });

    // 2a. Shared countdowns: drop their participant row, so access ends and
    //     they stop appearing in the people list.
    try {
      final shared = await _db
          .collectionGroup('participants')
          .where('userId', isEqualTo: targetUid)
          .get();
      for (final row in shared.docs) {
        final eventRef = row.reference.parent.parent;
        if (eventRef == null) continue;
        try {
          await eventRef.collection('participants').doc(targetUid).delete();
        } catch (error) {
          debugPrint('[datedawn] Block: could not remove $targetUid from '
              '${eventRef.id}: $error');
        }
      }
    } catch (error) {
      debugPrint('[datedawn] Block: could not list shared countdowns: $error');
    }

    // 2b. Pending invitations between the two of you, both directions. Sent
    //     ones would otherwise keep arriving in their inbox; received ones would
    //     keep asking this user to let the person back in.
    try {
      final mine =
          await _invitations.where('invitedBy', isEqualTo: userId).get();
      final theirs =
          await _invitations.where('invitedBy', isEqualTo: targetUid).get();
      String inviteeOf(Map<String, dynamic> data) =>
          ((data['inviteeEmail'] as String?) ?? '').toLowerCase();
      // Invites this user sent to the blocked address, and invites the blocked
      // account sent back. Anything else (this user's own inbox) is left alone.
      final doomed = [
        ...mine.docs
            .where((d) => email.isNotEmpty && inviteeOf(d.data()) == email),
        ...theirs.docs
            .where((d) => email.isEmpty || inviteeOf(d.data()) != email),
      ];
      for (final doc in doomed) {
        try {
          await doc.reference.delete();
        } catch (error) {
          debugPrint(
              '[datedawn] Block: could not delete invitation ${doc.id}: $error');
        }
      }
    } catch (error) {
      debugPrint('[datedawn] Block: could not clear invitations: $error');
    }

    // 3. Shared circles: leave them. Rules let a member remove only themselves.
    try {
      final mine =
          await _circles.where('memberIds', arrayContains: userId).get();
      final theirs =
          await _circles.where('memberIds', arrayContains: targetUid).get();
      final theirsIds = theirs.docs.map((d) => d.id).toSet();
      for (final circle in mine.docs) {
        if (!theirsIds.contains(circle.id)) continue;
        try {
          await leaveCircle(circleId: circle.id, userId: userId);
        } catch (error) {
          debugPrint('[datedawn] Block: could not leave circle ${circle.id}: '
              '$error');
        }
      }
    } catch (error) {
      debugPrint('[datedawn] Block: could not list shared circles: $error');
    }

    // 4. Recents, so the person is not offered as an invitee straight after.
    if (email.isNotEmpty) {
      try {
        final recents = await _recentContacts(userId).get();
        for (final doc in recents.docs) {
          final rowEmail =
              ((doc.data()['email'] as String?) ?? '').toLowerCase();
          if (rowEmail == email || doc.id == targetUid) {
            await doc.reference.delete();
          }
        }
      } catch (error) {
        debugPrint('[datedawn] Block: could not prune recents: $error');
      }
    }
  }

  /// Unblocks someone. Only the local block row is removed — the countdowns and
  /// circle memberships it cut are not restored, because the other person
  /// should not be silently re-granted access they lost.
  Future<void> unblockUser({
    required String userId,
    required String targetUid,
  }) async {
    await _blocked(userId).doc(targetUid).delete();
  }

  /// Whether this user has blocked [targetUid] or their email.
  Future<bool> isBlocked({
    required String userId,
    required String targetUid,
    String targetEmail = '',
  }) async {
    final snap = await _blocked(userId).get();
    final email = targetEmail.trim().toLowerCase();
    return snap.docs.any((d) {
      if (d.id == targetUid) return true;
      final rowEmail = ((d.data()['email'] as String?) ?? '').toLowerCase();
      return email.isNotEmpty && rowEmail == email;
    });
  }

  /// Deletes a circle outright. Owner only.
  ///
  /// **The documents are removed, the countdowns are not.** A circle is a
  /// sharing group, not a container: `events.sharedWithCircleIds` is what made
  /// a countdown visible to the group, so deleting the circle also strips its
  /// id from every countdown that referenced it. Leaving those ids behind would
  /// keep the events matched by `fetchCircleShared`, and worse, would leave a
  /// dangling id that could silently re-attach if an id were ever reused.
  ///
  /// Member rows go too — they belong to the circle and nothing else reads them.
  ///
  /// **The countdown unshares are committed BEFORE the circle is deleted, in
  /// their own batches.** This is the fix for "I own this circle but cannot
  /// delete it": the unshare update is authorised per countdown (owner/editor
  /// of that countdown), while deleting the circle is authorised by the circle
  /// owner. In one batch, a single countdown the caller can see but not edit
  /// fails its update, and because a batch is atomic Firestore rejects the whole
  /// thing — taking the perfectly legal circle delete down with it, surfaced as a
  /// bare `permission-denied`. Splitting them means a countdown that refuses the
  /// unshare is simply skipped, and the circle is still deleted.
  ///
  /// Everything is chunked: a batch caps at 500 writes and a circle can be
  /// shared with more countdowns than that.
  Future<void> deleteCircle({
    required String circleId,
    required String userId,
  }) async {
    final circleDoc = await _circles.doc(circleId).get();
    final data = circleDoc.data();
    if (data == null) return;

    // Fail early with a readable message rather than letting the rules refuse
    // the first write of the batch.
    if (data['ownerId'] != userId) {
      throw const DataFailure('Only the circle owner can delete it.');
    }

    // Every countdown shared with this circle, so the reference can be pulled.
    //
    // **Wrapped, and that is the whole fix for "I own this circle but cannot
    // delete it".** The read rule for a countdown the caller can see only as a
    // *participant* (`isParticipant(eventId)`) resolves a subcollection `get()`,
    // which Firestore cannot evaluate for a collection query — so ONE countdown
    // in this result set that the circle owner can read but not prove (typically
    // one their partner created and shared with the circle) made the entire
    // query fail with `permission-denied`. That exception used to escape this
    // method and surface as "You do not have permission to do that." on a circle
    // the caller unambiguously owns. The circle delete itself needs none of
    // these documents, so a refused query degrades to "no countdowns to unshare"
    // rather than blocking the delete — exactly the same best-effort posture the
    // per-countdown unshare below already takes.
    var sharedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    try {
      final shared = await _events
          .where('sharedWithCircleIds', arrayContains: circleId)
          .get();
      sharedDocs = shared.docs;
    } on FirebaseException catch (error) {
      debugPrint(
        '[datedawn] Could not list countdowns shared with circle $circleId '
        '(${error.code}). Deleting the circle anyway; any countdown still '
        'pointing at it is cleaned up on its next open. If this is '
        'permission-denied, deploy the rules: '
        'firebase deploy --only firestore:rules',
      );
    } catch (error) {
      debugPrint(
        '[datedawn] Could not list countdowns shared with circle $circleId: '
        '$error',
      );
    }

    // Member rows to remove alongside the circle document. Best-effort too: a
    // refusal here must not take the circle delete down with it.
    var memberRefs = <DocumentReference<Map<String, dynamic>>>[];
    try {
      final members = await _circles.doc(circleId).collection('members').get();
      memberRefs = members.docs.map((d) => d.reference).toList();
    } catch (error) {
      debugPrint(
        '[datedawn] Could not list members of circle $circleId before '
        'deleting it: $error',
      );
    }

    // 1. Unshare every countdown, on its own, before touching the circle.
    //    Best-effort per countdown: one the caller cannot edit must not block
    //    the delete. The reference is stripped even if the caller is a viewer
    //    via the `sharedWithMemberIds`-only update branch of the rule.
    await _unshareCircleFromEvents(circleId, sharedDocs);

    // 2. Re-derive `sharedWithMemberIds` for those countdowns while the circle
    //    is still readable — the prune needs the circle's own member list, so it
    //    must run before the circle document is gone.
    await _pruneDeletedCircleShares(circleId, sharedDocs);

    // 3. Delete the circle document and its member rows. Nothing here touches
    //    an event, so this batch is authorised by the circle owner alone and
    //    cannot be poisoned by a countdown the owner does not own.
    final refs = <DocumentReference<Map<String, dynamic>>>[
      // The member rows.
      ...memberRefs,
      // The circle document itself.
      _circles.doc(circleId),
    ];

    for (var i = 0; i < refs.length; i += 400) {
      final end = i + 400 > refs.length ? refs.length : i + 400;
      final batch = _db.batch();
      for (final ref in refs.sublist(i, end)) {
        batch.delete(ref);
      }
      try {
        await batch.commit();
      } catch (error) {
        // The circle document itself is the thing the user asked to remove and
        // the only write here the owner is guaranteed to be authorised for; it
        // is deleted in its own request below rather than being held hostage by
        // a member row that refuses.
        debugPrint(
          '[datedawn] Could not delete a batch of circle $circleId refs '
          '($error). Retrying one at a time.',
        );
        for (final ref in refs.sublist(i, end)) {
          try {
            await ref.delete();
          } catch (singleError) {
            debugPrint(
              '[datedawn] Could not delete ${ref.path} while deleting circle '
              '$circleId: $singleError',
            );
          }
        }
      }
    }
  }

  /// Strips [circleId] from `sharedWithCircleIds` on every countdown in
  /// [events], one batch at a time and best-effort per countdown.
  ///
  /// Split out of [deleteCircle] so the countdown updates and the circle delete
  /// are never in the same atomic batch: a single countdown the caller cannot
  /// edit used to fail the whole batch and take the circle delete with it.
  Future<void> _unshareCircleFromEvents(
    String circleId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  ) async {
    for (var i = 0; i < events.length; i += 400) {
      final end = i + 400 > events.length ? events.length : i + 400;
      final chunk = events.sublist(i, end);
      try {
        final batch = _db.batch();
        for (final event in chunk) {
          // Unshare rather than delete the countdown.
          batch.update(event.reference, {
            'sharedWithCircleIds': FieldValue.arrayRemove([circleId]),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
        await batch.commit();
      } catch (error) {
        // A countdown the caller cannot edit — typically someone else's, where
        // they are only a viewer. Fall back to one-by-one so the rest of the
        // chunk still gets unshared; the circle delete must not be blocked by
        // it.
        debugPrint(
          '[datedawn] Could not unshare circle $circleId from a batch of '
          'countdowns ($error). Retrying one at a time.',
        );
        for (final event in chunk) {
          try {
            await _events.doc(event.id).update({
              'sharedWithCircleIds': FieldValue.arrayRemove([circleId]),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          } catch (singleError) {
            debugPrint(
              '[datedawn] Could not unshare circle $circleId from '
              'countdown ${event.id}: $singleError',
            );
          }
        }
      }
    }
  }

  /// Recomputes `sharedWithMemberIds` on each event after [circleId] was
  /// deleted, **subtractively**.
  ///
  /// The naive version rebuilt the array from the circles that *remain* by
  /// reading each of them. That cannot work in general: reading
  /// `circles/{other}` needs `uid() in memberIds` on THAT circle, and the person
  /// deleting this circle is frequently not in it. One denied read aborted the
  /// whole loop (it was wrapped in a single `try`), so a countdown shared with
  /// two circles kept the deleted circle's members in its visibility array —
  /// the countdown went on being served to people whose only claim to it was
  /// the circle that no longer exists.
  ///
  /// So instead: start from the members of the circle being deleted — which the
  /// deleter is guaranteed to be able to read, they own it — and remove exactly
  /// those, keeping any uid that some *other* remaining circle still covers.
  /// A remaining circle whose members cannot be read is treated as "covers
  /// everyone" (we simply do not remove anyone on its behalf): leaving a uid in
  /// the array is a harmless over-share that the next resync fixes, whereas
  /// removing someone who should still see the countdown silently hides it from
  /// them.
  ///
  /// Runs **before** the circle document is removed, so the member list is still
  /// there to read.
  Future<void> _pruneDeletedCircleShares(
    String circleId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  ) async {
    if (events.isEmpty) return;

    // The members this circle was responsible for. Read once, from the circle
    // the caller owns — never a read that can be denied.
    final deletedMembers = <String>{};
    try {
      final doc = await _circles.doc(circleId).get();
      final raw = doc.data()?['memberIds'];
      if (raw is List) deletedMembers.addAll(raw.whereType<String>());
      if (deletedMembers.isEmpty) {
        final snap = await _circles.doc(circleId).collection('members').get();
        deletedMembers.addAll(snap.docs.map((d) => d.id));
      }
    } catch (error) {
      debugPrint(
        '[datedawn] Could not read members of circle $circleId while pruning: '
        '$error',
      );
    }
    if (deletedMembers.isEmpty) return;

    for (final event in events) {
      final data = event.data();
      final remaining = (data['sharedWithCircleIds'] as List? ?? const [])
          .whereType<String>()
          .where((id) => id != circleId)
          .toList();
      final current = (data['sharedWithMemberIds'] as List? ?? const [])
          .whereType<String>()
          .toSet();

      // Anyone a remaining circle still covers. A circle we cannot read is
      // skipped, which leaves its members in `current` rather than dropping them.
      final stillCovered = <String>{};
      for (final id in remaining) {
        try {
          final doc = await _circles.doc(id).get();
          final raw = doc.data()?['memberIds'];
          if (raw is List) stillCovered.addAll(raw.whereType<String>());
        } catch (error) {
          debugPrint(
            '[datedawn] Could not read circle $id while pruning $circleId; '
            'leaving its members shared: $error',
          );
          stillCovered.addAll(current);
        }
      }

      final next = current
          .where(
              (id) => !deletedMembers.contains(id) || stillCovered.contains(id))
          .toList();
      if (next.length == current.length && next.every(current.contains)) {
        // Nothing to do for this event.
        continue;
      }
      try {
        await _events.doc(event.id).update({
          'sharedWithMemberIds': next,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (error) {
        // Per-event, so one countdown that refuses the write does not stop the
        // others from being pruned — and never propagates to fail the delete.
        debugPrint(
          '[datedawn] Could not prune shares for $circleId on event '
          '${event.id}: $error',
        );
      }
    }
  }

  /// Shares (or unshares) a countdown with a circle.
  ///
  /// `sharedWithCircleIds` is the single source of truth for circle visibility
  /// and is what both the client query and the security rule read, so adding
  /// and removing are the same write.
  Future<void> setEventCircles({
    required CountdownEvent event,
    required String userId,
    required List<String> circleIds,
  }) async {
    if (!event.canEdit(userId)) {
      throw const DataFailure(
          'Only admins and editors can share this countdown.');
    }
    // The circles are not passed in here, so each one is read directly to
    // collect its members. Kept in lockstep with the circle list because the
    // visibility rule reads this array: a stale one would either hide the
    // countdown from someone who should see it, or keep showing it to someone
    // who has left.
    final memberIds = <String>{};
    for (final circleId in circleIds) {
      try {
        final doc = await _circles.doc(circleId).get();
        final data = doc.data();
        final raw = data?['memberIds'];
        if (raw is List) memberIds.addAll(raw.whereType<String>());
        if (memberIds.isEmpty || raw == null) {
          final snap = await _circles.doc(circleId).collection('members').get();
          memberIds.addAll(snap.docs.map((d) => d.id));
        }
      } catch (error) {
        debugPrint('[datedawn] Could not read members of $circleId: $error');
      }
    }
    await _events.doc(event.id).update({
      'sharedWithCircleIds': circleIds,
      'sharedWithMemberIds': memberIds.toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Syncs the user's public profile into the `users` collection so email lookup
  /// for invitations works cleanly.
  Future<void> syncUserProfile(AppUser user) async {
    if (user.id.isEmpty || user.email.isEmpty) return;
    try {
      await _db.collection('users').doc(user.id).set({
        'email': user.email.toLowerCase(),
        if (user.displayName != null) 'displayName': user.displayName,
        if (user.photoUrl != null) 'photoUrl': user.photoUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (_) {
      // Profile sync is best-effort
    }
  }

  /// Uses the users collection to turn an email address into an account, so an
  /// invite can be added straight to a countdown when the person already has an
  /// account rather than waiting for a signup.
  ///
  /// Returns `userId` plus any profile fields that are actually present —
  /// absent ones are omitted rather than stringified to `"null"`, so a caller
  /// can pass `displayName`/`photoUrl` straight through without a bogus value.
  Future<Map<String, String>?> lookupUserByEmail(String email) async {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return null;
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: normalised)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final data = doc.data();
      return {
        'userId': doc.id,
        for (final key in const ['email', 'displayName', 'photoUrl'])
          if (data[key] is String && (data[key] as String).isNotEmpty)
            key: data[key] as String,
      };
    } catch (_) {
      return null;
    }
  }

  /// The public profile for a uid, in the same shape as [lookupUserByEmail].
  ///
  /// Needed when the caller has already resolved a uid but still needs the
  /// email an `invitations` document has to be addressed to.
  Future<Map<String, String>?> lookupUserById(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) return null;
      return {
        for (final key in const ['email', 'displayName', 'photoUrl'])
          if (data[key] is String && (data[key] as String).isNotEmpty)
            key: data[key] as String,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> addNote({
    required String eventId,
    required String userId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final id = _uuid.v4();
    final now = DateTime.now();
    await _events.doc(eventId).collection('notes').doc(id).set({
      'id': id,
      'userId': userId,
      'text': text.trim(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // ---------------------------------------------------------------------------
  // Recent contacts
  // ---------------------------------------------------------------------------

  /// Live stream of the people this user has invited before, most recently
  /// invited first.
  ///
  /// The invite field renders these as suggestions, so the address you typed
  /// last time is offered before you type it again. Ordered in memory rather
  /// than by the query, so no composite index is required.
  Stream<List<RecentContact>> watchRecentContacts(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _recentContacts(userId).snapshots().map((snap) {
      final items = snap.docs
          .map((d) => RecentContact.fromMap(d.id, d.data()))
          .where((c) => c.email.contains('@'))
          .toList()
        ..sort((a, b) {
          final byRecency = b.lastInvitedAt.compareTo(a.lastInvitedAt);
          if (byRecency != 0) return byRecency;
          return b.inviteCount.compareTo(a.inviteCount);
        });
      return items;
    });
  }

  /// Records [contacts] as recently invited, so they are suggested next time.
  ///
  /// Best-effort by design: it runs after an invitation has already been sent,
  /// so a failure here must never turn a successful invite into an error — it
  /// degrades to "they are not remembered", which only costs a retyped address.
  ///
  /// Each person is stamped with `lastInvitedAt: now`, which is what moves them
  /// to the top of the suggestion list on the next invite. `inviteCount` is
  /// incremented so someone invited repeatedly outranks a one-off on a tie.
  Future<void> rememberInvitedContacts({
    required String userId,
    required Iterable<InvitationRecipient> contacts,
  }) async {
    if (userId.isEmpty) return;
    final now = DateTime.now();
    final seen = <String>{};
    for (final contact in contacts) {
      final email = contact.email.trim().toLowerCase();
      if (email.isEmpty || !email.contains('@')) continue;
      // Dedupe within one call so inviting the same person twice in a batch
      // does not double-count them.
      if (!seen.add(email)) continue;
      try {
        // Keyed by uid when there is one, so a person invited under a changed
        // display name updates the same row; falling back to the email keeps a
        // contact recorded even when the account lookup had nothing to match.
        final docId = contact.userId.isNotEmpty
            ? contact.userId
            : email.replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final ref = _recentContacts(userId).doc(docId);
        final existing = await ref.get();
        final previous = existing.data();
        final count = ((previous?['inviteCount'] as num?)?.toInt() ?? 0) + 1;
        await ref.set({
          'userId': contact.userId,
          'email': email,
          if (contact.displayName != null) 'displayName': contact.displayName,
          if (contact.photoUrl != null) 'photoUrl': contact.photoUrl,
          'lastInvitedAt': Timestamp.fromDate(now),
          'inviteCount': count,
        }, SetOptions(merge: true));
      } catch (error) {
        debugPrint('[datedawn] Could not remember contact $email: $error');
      }
    }
  }

  /// Removes one person from the suggestion list.
  ///
  /// People change addresses and jobs; a suggestion that cannot be dismissed is
  /// worse than no suggestion at all.
  Future<void> forgetRecentContact({
    required String userId,
    required RecentContact contact,
  }) async {
    if (userId.isEmpty) return;
    final docId = contact.userId.isNotEmpty
        ? contact.userId
        : contact.email.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    try {
      await _recentContacts(userId).doc(docId).delete();
    } catch (error) {
      debugPrint(
        '[datedawn] Could not forget contact ${contact.email}: $error',
      );
    }
  }

  /// Duplicates a countdown a year on, keeping the title so the copy can be
  /// tweaked — the same behaviour as the web app's "Duplicate" action.
  Future<CountdownEvent> duplicateEvent({
    required CountdownEvent event,
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) {
    return createEvent(
      userId: userId,
      email: email,
      title: event.title,
      description: event.description,
      at: DateTime(event.at.year + 1, event.at.month, event.at.day,
          event.at.hour, event.at.minute),
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// A short, shareable summary of a countdown.
  static String shareText(CountdownEvent event) {
    final remaining = remainingUntil(event.at);
    final phrase = describeRemaining(remaining);
    return '${event.title} — ${formatMomentFull(event.at)}\n'
        '${remaining.isPast ? 'It has arrived.' : '$phrase to go.'}';
  }
}
