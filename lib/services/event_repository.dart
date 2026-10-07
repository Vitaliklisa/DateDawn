import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/circles.dart';
import '../core/countdown.dart';
import '../core/models.dart';
import '../core/notifications.dart';
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
  /// Wired to Supabase in `app_providers.dart`. It is injected rather than
  /// imported so this class stays a Firestore-only data layer (and stays
  /// testable without a Supabase client). A failure here must never fail the
  /// user's action — the countdown was already shared, the inbox line is a
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
    final created =
        _events.where('createdBy', isEqualTo: userId).limit(100).snapshots();

    final shared = _db
        .collectionGroup('participants')
        .where('userId', isEqualTo: userId)
        .snapshots();

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
    void emit({bool force = false}) {
      // Owned events win on id collision: they are the authoritative copy and
      // are ordered in memory.
      final byId = <String, CountdownEvent>{
        for (final e in latestOwned) e.id: e
      };
      fetchedShared.forEach((id, event) => byId.putIfAbsent(id, () => event));

      final merged = byId.values.toList()..sort((a, b) => a.at.compareTo(b.at));
      if (merged.isEmpty && !emittedAnything && !force) return;
      emittedAnything = true;
      if (!controller.isClosed) controller.add(merged);
    }

    /// Runs the `whereIn` queries for whatever ids are missing from
    /// `fetchedShared`. Both the participant feed and the circle feed write into
    /// `latestSharedIds`, so one collect-and-fetch pass covers both.
    ///
    /// The chunks run in parallel: fetching them in sequence made a user with
    /// more than 30 shared countdowns wait one round-trip per chunk, which is
    /// exactly the "why is this so slow" case. A re-entrancy guard collapses
    /// the overlapping calls that the two feeds trigger together.
    bool fetching = false;
    bool fetchAgain = false;
    Future<void> fetchShared() async {
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
          final wanted = latestSharedIds
              .where((id) => !fetchedShared.containsKey(id))
              .toList();
          if (wanted.isEmpty) break;

          // `whereIn` accepts 30 values per query; chunk to stay inside that.
          final chunks = <List<String>>[];
          for (var i = 0; i < wanted.length; i += 30) {
            final end = i + 30 > wanted.length ? wanted.length : i + 30;
            chunks.add(wanted.sublist(i, end));
          }

          final snaps = await Future.wait(
            chunks.map(
              (chunk) async {
                try {
                  return await _events
                      .where(FieldPath.documentId, whereIn: chunk)
                      .get();
                } catch (_) {
                  // A chunk that fails (offline, permission) is skipped rather
                  // than killing the whole stream.
                  return null;
                }
              },
            ),
          );
          if (disposed) return;

          final fetched = <String, CountdownEvent>{};
          for (final snap in snaps) {
            if (snap == null) continue;
            for (final doc in snap.docs) {
              if (doc.data()['deletedAt'] == null) {
                fetched[doc.id] = _fromDoc(doc);
              }
            }
          }
          fetchedShared = {...fetchedShared, ...fetched};
          emit();
        } while (fetchAgain);
      } finally {
        fetching = false;
      }
    }

    /// Queries every event shared with any circle the user belongs to.
    Future<void> fetchCircleShared() async {
      if (latestCircleIds.isEmpty) return;
      try {
        final snaps = await Future.wait(
          latestCircleIds.map(
            (circleId) => _events
                .where('sharedWithCircleIds', arrayContains: circleId)
                .get(),
          ),
        );
        if (disposed) return;
        final ids = <String>{...latestSharedIds};
        for (final snap in snaps) {
          for (final doc in snap.docs) {
            if (doc.data()['deletedAt'] != null) continue;
            // Owned events are already in `latestOwned`; skip re-fetching them.
            if (latestOwned.any((e) => e.id == doc.id)) continue;
            ids.add(doc.id);
          }
        }
        latestSharedIds = ids;
        await fetchShared();
      } catch (_) {
        // Offline or permission-denied: keep whatever is already on screen.
      }
    }

    final subOwned = created.listen((snap) {
      latestOwned = snap.docs
          .where((doc) => doc.data()['deletedAt'] == null)
          .map(_fromDoc)
          .toList();
      emit();
      // If this first owned snapshot is empty, the held-back emission above
      // would leave the UI on its spinner forever for a genuinely empty
      // account. Give the shared and circle feeds a moment to answer, then
      // force a settle so "no countdowns" is shown rather than "still loading".
      if (!emittedAnything) {
        unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () {
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
      unawaited(fetchShared());
    }, onError: controller.addError);

    final subCircles = myCircles.listen((snap) {
      latestCircleIds = snap.docs.map((d) => d.id).toSet();
      unawaited(fetchCircleShared());
    }, onError: controller.addError);

    controller.onCancel = () async {
      disposed = true;
      await subOwned.cancel();
      await subShared.cancel();
      await subCircles.cancel();
    };

    return controller.stream;
  }

  CountdownEvent _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    // Participants live in a subcollection, so they are not part of the parent
    // document payload. They are filled in by `watchParticipants` where needed;
    // the fields a countdown face needs are all on the parent.
    return CountdownEvent.fromDoc(doc.id, data);
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
    });
    batch.set(_events.doc(id).collection('participants').doc(userId), {
      'email': email.toLowerCase(),
      'role': ParticipantRole.admin.name,
      'inviteStatus': InviteStatus.accepted.name,
      'joinedAt': Timestamp.fromDate(now),
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });

    final autoParticipants = <Participant>[];
    for (final circleId in validCircleIds) {
      final circle = circles.firstWhere((c) => c.id == circleId);
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
      // `circlesProvider` streams circle documents without their `members`
      // subcollection, so the list here is usually empty. Hydrate it from the
      // subcollection on demand — without this the couple auto-share silently
      // did nothing, because the loop below had nobody to iterate.
      var members = circle.members;
      if (members.isEmpty) {
        final memberSnap =
            await _circles.doc(circle.id).collection('members').get();
        members = memberSnap.docs
            .map((d) => CircleMember.fromMap(d.id, d.data()))
            .toList();
      }
      for (final member in members) {
        if (member.userId == userId) continue;
        batch.set(
          _events.doc(id).collection('participants').doc(member.userId),
          {
            'email': member.email,
            'role': ParticipantRole.editor.name,
            'inviteStatus': InviteStatus.accepted.name,
            'joinedAt': Timestamp.fromDate(now),
            if (member.displayName != null) 'displayName': member.displayName,
            if (member.photoUrl != null) 'photoUrl': member.photoUrl,
          },
          SetOptions(merge: true),
        );
        autoParticipants.add(
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
    }

    await batch.commit();

    return CountdownEvent(
      id: id,
      title: title.trim(),
      description: description.trim(),
      at: at,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      sharedWithCircleIds: validCircleIds,
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

    if (targetUserId != null) {
      await _events
          .doc(event.id)
          .collection('participants')
          .doc(targetUserId)
          .set({
        'email': target,
        'role': role.name,
        'inviteStatus': InviteStatus.pending.name,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }, SetOptions(merge: true));
      // Tell the invitee there is something waiting for them. This is the line
      // that makes the Supabase inbox useful rather than permanently empty.
      await _notify(
        userId: targetUserId,
        title: 'You were invited to “${event.title}”',
        body: 'Open Invitations to accept or decline.',
        kind: NotificationKind.invitation,
      );
      return;
    }

    final id = _uuid.v4();
    await _invitations.doc(id).set({
      'eventId': event.id,
      'invitedBy': inviterId,
      'inviteeEmail': target,
      'role': role.name,
      'status': InviteStatus.pending.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'eventTitle': event.title,
    });
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
    _guardInvitation(invitation);

    final batch = _db.batch();
    batch.set(
      _events.doc(invitation.eventId).collection('participants').doc(userId),
      {
        'email': email.toLowerCase(),
        'role': invitation.role.name,
        'inviteStatus': InviteStatus.accepted.name,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
      SetOptions(merge: true),
    );
    batch.update(_invitations.doc(invitation.id),
        {'status': InviteStatus.accepted.name});
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
  }) async {
    await _invitations.doc(invitation.id).update(
      {'status': InviteStatus.rejected.name},
    );
    await _notifyInviter(
      inviterId: invitation.invitedBy,
      eventId: invitation.eventId,
      eventTitle: invitation.eventTitle,
      responderEmail: responderEmail ?? '',
      responderName: responderName,
      accepted: false,
    );
  }

  void _guardInvitation(Invitation invitation) {
    if (invitation.isExpired) {
      throw const DataFailure('That invitation has expired.');
    }
    if (invitation.status != InviteStatus.pending) {
      throw const DataFailure('That invitation is no longer pending.');
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

    // Mirror the same event into the Supabase inbox, which is the feed the
    // Notifications screen streams live. Without this the inbox table stayed
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
  /// If the address already has an account the invitation is still issued as a
  /// pending invitation rather than an instant join — joining a standing group
  /// should always be the invitee's choice, in contrast to a countdown shared
  /// with an existing collaborator.
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

    // If the invitee already has an account, drop a line in their inbox so they
    // notice without having to open the Invitations screen first.
    final match = await lookupUserByEmail(target);
    final inviteeId = match?['userId'];
    if (inviteeId != null && inviteeId.isNotEmpty && inviteeId != inviterId) {
      await _notify(
        userId: inviteeId,
        title: circle.isCouple
            ? '${inviterName ?? 'Someone'} invited you to be their partner'
            : 'You were invited to “${circle.name}”',
        body: 'Open Invitations to accept or decline.',
        kind: NotificationKind.circle,
      );
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

    // Tell the person who invited them. Best-effort: they have already joined.
    if (invitation.invitedBy.isNotEmpty &&
        invitation.invitedBy != userId) {
      final who = (displayName?.trim().isNotEmpty ?? false)
          ? displayName!
          : email;
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

  Future<void> rejectCircleInvitation(CircleInvitation invitation) async {
    await _circleInvitations
        .doc(invitation.id)
        .update({'status': InviteStatus.rejected.name});
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
    await _events.doc(event.id).update({
      'sharedWithCircleIds': circleIds,
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
