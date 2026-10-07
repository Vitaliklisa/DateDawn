import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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

/// All reads and writes for Date Dawn, backed by Supabase (Postgres).
///
/// **Identity.** Firebase Auth issues the ID token; Supabase verifies it and
/// exposes the Firebase uid as `auth.uid()`. Every query here relies on the
/// row-level-security policies in `supabase/schema.sql` rather than passing a
/// uid the server would have to trust, so a caller cannot read or write another
/// user's rows even by crafting a request.
///
/// **Why the client still passes `userId`.** The policies scope the rows; the
/// `userId` parameters are what the UI already knows, and are used for the
/// columns the caller legitimately owns (`created_by`, `user_id`). They are
/// never the authorisation decision — RLS is.
///
/// Tables (see `supabase/schema.sql` for the enforced shape):
///
/// ```
/// events               title, description, at, created_by, deleted_at
/// event_participants   event_id, user_id, role, invite_status
/// event_circles        event_id, circle_id
/// event_notes          event_id, user_id, text
/// circles              name, owner_id, is_couple, emoji
/// circle_members       circle_id, user_id, role
/// invitations          event_id, invited_by, invitee_email, status
/// circle_invitations   circle_id, invited_by, invitee_email, status
/// responses            recipient_id, event_id, accepted, is_read
/// notifications        user_id, title, body, type, is_read
/// profiles             id, full_name, avatar_url
/// ```
class EventRepository {
  EventRepository({SupabaseClient? client, this.notificationSink})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Delivers an in-app notification to a recipient, best-effort.
  ///
  /// Wired to Supabase in `app_providers.dart`. Injected rather than called
  /// directly so the repository stays testable without a live client, and so a
  /// failure to notify can never fail the user's action.
  final Future<void> Function({
    required String userId,
    required String title,
    required String body,
    required NotificationKind kind,
  })? notificationSink;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Live stream of every event the user created, was invited to, or can see
  /// through a circle they belong to.
  ///
  /// One query covers all three cases because the `events` RLS policy expresses
  /// exactly that rule. Postgres applies it per row, so the client does not
  /// merge three feeds — which is what the Firestore version had to do, and
  /// what made it slow.
  ///
  /// `deleted_at` is filtered in memory rather than in the query: a soft-deleted
  /// row must still be filtered by the policy, and Supabase's stream builder
  /// cannot express "is null" as an additional filter without dropping realtime
  /// updates for the rows it does match.
  Stream<List<CountdownEvent>> watchEvents(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _client.from('events').stream(primaryKey: ['id']).order('at').map(
          (rows) => rows
              .where((row) => row['deleted_at'] == null)
              .map((row) => CountdownEvent.fromRow(row))
              .toList(),
        );
  }

  /// Live stream of one event's participants.
  Stream<List<Participant>> watchParticipants(String eventId) => _client
      .from('event_participants')
      .stream(primaryKey: ['event_id', 'user_id'])
      .eq('event_id', eventId)
      .map((rows) => rows.map((row) => Participant.fromRow(row)).toList());

  /// Live stream of an event's notes, oldest first.
  Stream<List<EventNote>> watchNotes(String eventId) => _client
      .from('event_notes')
      .stream(primaryKey: ['id'])
      .eq('event_id', eventId)
      .order('created_at')
      .map((rows) => rows.map((row) => EventNote.fromRow(row)).toList());

  /// One event with its participants, for a deep link with no cached copy.
  Future<CountdownEvent> fetchEvent(String eventId) async {
    final row =
        await _client.from('events').select().eq('id', eventId).maybeSingle();
    if (row == null) {
      throw const DataFailure('That countdown no longer exists.');
    }
    final participants = await _client
        .from('event_participants')
        .select()
        .eq('event_id', eventId);
    return CountdownEvent.fromRow(row).copyWith(
      participants: participants.map((p) => Participant.fromRow(p)).toList(),
    );
  }

  /// Live stream of the circles this user belongs to.
  ///
  /// The `circles` policy already limits this to circles the caller owns or
  /// belongs to, so no client-side filtering is needed.
  Stream<List<Circle>> watchCircles(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _client
        .from('circles')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map((row) => Circle.fromRow(row)).toList());
  }

  /// Live stream of a circle's members, hydrated from `circle_members`.
  Stream<List<CircleMember>> watchCircleMembers(String circleId) => _client
      .from('circle_members')
      .stream(primaryKey: ['circle_id', 'user_id'])
      .eq('circle_id', circleId)
      .map((rows) => rows.map((row) => CircleMember.fromRow(row)).toList());

  /// Live stream of pending countdown invitations. RLS already hides every
  /// invitation that is not addressed to the caller.
  Stream<List<Invitation>> watchInvitations(String email) {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return Stream.value(const []);
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((rows) => rows
            .map((row) => Invitation.fromRow(row))
            .where((invite) => !invite.isExpired)
            .toList());
  }

  /// Live stream of pending circle invitations. RLS hides the rest.
  Stream<List<CircleInvitation>> watchCircleInvitations(String email) {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return Stream.value(const []);
    return _client
        .from('circle_invitations')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((rows) => rows
            .map((row) => CircleInvitation.fromRow(row))
            .where((invite) => !invite.isExpired)
            .toList());
  }

  /// Live stream of the answers to invitations this user sent.
  Stream<List<InvitationResponse>> watchResponses(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _client
        .from('responses')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('responded_at', ascending: false)
        .map((rows) =>
            rows.map((row) => InvitationResponse.fromRow(row)).toList());
  }

  Future<void> markResponseRead(String responseId) async {
    await _client
        .from('responses')
        .update({'is_read': true}).eq('id', responseId);
  }

  // ---------------------------------------------------------------------------
  // Writes - countdowns
  // ---------------------------------------------------------------------------

  /// Creates a countdown.
  ///
  /// The creator's accepted admin row is written immediately after, so the
  /// countdown is never briefly ownerless.
  ///
  /// **Couple sharing.** A couple circle in `autoShareCircleIds` attaches the
  /// countdown and gives every member an accepted `editor` row — no invitation
  /// to accept. A non-couple circle is attached for visibility only, so a
  /// friend group is never silently subscribed to private plans.
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

    // Only circles the creator actually belongs to are honoured. RLS enforces
    // this too; checking here means a bad id fails with a readable message.
    final validCircleIds = autoShareCircleIds
        .where((circleId) =>
            circles.any((c) => c.id == circleId && c.contains(userId)))
        .toList();

    final now = DateTime.now();
    final Map<String, dynamic> created;
    try {
      created = await _client
          .from('events')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'at': at.toUtc().toIso8601String(),
            'created_by': userId,
          })
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }

    final eventId = created['id'] as String;

    await _client.from('event_participants').insert({
      'event_id': eventId,
      'user_id': userId,
      'email': email.toLowerCase(),
      'role': ParticipantRole.admin.name,
      'invite_status': InviteStatus.accepted.name,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
    });

    final autoParticipants = <Participant>[];

    for (final circleId in validCircleIds) {
      final circle = circles.firstWhere((c) => c.id == circleId);

      await _client.from('event_circles').insert({
        'event_id': eventId,
        'circle_id': circleId,
      });

      // Only a couple circle joins silently.
      if (!circle.isCouple) continue;

      // `circlesProvider` streams circle rows without their members, so the
      // embedded list is usually empty. Read it here, or the couple share
      // silently does nothing.
      var members = circle.members;
      if (members.isEmpty) {
        final rows = await _client
            .from('circle_members')
            .select()
            .eq('circle_id', circleId);
        members = rows.map((r) => CircleMember.fromRow(r)).toList();
      }

      for (final member in members) {
        if (member.userId == userId) continue;
        await _client.from('event_participants').upsert({
          'event_id': eventId,
          'user_id': member.userId,
          'email': member.email,
          'role': ParticipantRole.editor.name,
          'invite_status': InviteStatus.accepted.name,
          if (member.displayName != null) 'display_name': member.displayName,
          if (member.photoUrl != null) 'photo_url': member.photoUrl,
        });
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

    return CountdownEvent(
      id: eventId,
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

    try {
      await _client.from('events').update({
        'title': title.trim(),
        'description': description.trim(),
        'at': at.toUtc().toIso8601String(),
      }).eq('id', event.id);
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }
  }

  /// Soft-deletes by stamping `deleted_at`. Every read filters it out, so an
  /// accidental delete is recoverable and participant history is not orphaned.
  Future<void> deleteEvent(
      {required CountdownEvent event, required String userId}) async {
    if (!event.canManage(userId)) {
      throw const DataFailure('Only the owner can delete this countdown.');
    }
    try {
      await _client
          .from('events')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq(
              'id', event.id);
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }
  }

  /// Shares (or unshares) a countdown with circles.
  ///
  /// Diffed against what is already there, so a share that has not changed is a
  /// no-op rather than a delete-and-reinsert.
  Future<void> setEventCircles({
    required CountdownEvent event,
    required String userId,
    required List<String> circleIds,
  }) async {
    if (!event.canEdit(userId)) {
      throw const DataFailure(
          'Only admins and editors can share this countdown.');
    }

    final current = await _client
        .from('event_circles')
        .select('circle_id')
        .eq('event_id', event.id);
    final existing = current.map((row) => row['circle_id'] as String).toSet();
    final wanted = circleIds.toSet();

    final toAdd = wanted.difference(existing);
    final toRemove = existing.difference(wanted);

    if (toRemove.isNotEmpty) {
      await _client
          .from('event_circles')
          .delete()
          .eq('event_id', event.id)
          .inFilter('circle_id', toRemove.toList());
    }
    if (toAdd.isNotEmpty) {
      await _client.from('event_circles').insert([
        for (final circleId in toAdd)
          {'event_id': event.id, 'circle_id': circleId},
      ]);
    }
  }

  /// Duplicates a countdown a year on, keeping the title so the copy can be
  /// tweaked.
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

  // ---------------------------------------------------------------------------
  // Writes - invitations
  // ---------------------------------------------------------------------------

  /// Invites someone by email.
  ///
  /// If the address already has an account, a participant row is written
  /// straight away and shows up as pending in their app. Otherwise the
  /// invitation waits until that email signs up, which is why it is addressed
  /// by email as well as by uid.
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
    if (inviterEmail != null && inviterEmail.trim().toLowerCase() == target) {
      throw const DataFailure(cannotInviteSelfMessage);
    }
    if (knownUserId != null && knownUserId == inviterId) {
      throw const DataFailure(cannotInviteSelfMessage);
    }

    // Resolve the email to an account, if there is one.
    var targetUserId = knownUserId;
    if (targetUserId == null) {
      final match = await lookupUserByEmail(target);
      final resolvedId = match?['id'];
      if (resolvedId != null && resolvedId.isNotEmpty) {
        if (resolvedId == inviterId) {
          throw const DataFailure(cannotInviteSelfMessage);
        }
        targetUserId = resolvedId;
        displayName ??= match?['full_name'] as String?;
        photoUrl ??= match?['avatar_url'] as String?;
      }
    }

    try {
      await _client.from('invitations').insert({
        'event_id': event.id,
        'invited_by': inviterId,
        'invitee_email': target,
        if (targetUserId != null) 'invitee_id': targetUserId,
        'role': role.name,
        'event_title': event.title,
      });

      if (targetUserId != null) {
        await _client.from('event_participants').upsert({
          'event_id': event.id,
          'user_id': targetUserId,
          'email': target,
          'role': role.name,
          'invite_status': InviteStatus.pending.name,
          if (displayName != null) 'display_name': displayName,
          if (photoUrl != null) 'photo_url': photoUrl,
        });
      }
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }

    if (targetUserId != null) {
      await _notify(
        userId: targetUserId,
        title: 'You were invited to “${event.title}”',
        body: 'Open Invitations to accept or decline.',
        kind: NotificationKind.invitation,
      );
    }
  }

  /// Accepts an invitation addressed to the signed-in user.
  ///
  /// The invitation was matched by the caller's own uid or verified email, so a
  /// user can only ever accept an invite sent to them.
  Future<void> acceptInvitation({
    required Invitation invitation,
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    _guardInvitation(invitation);

    await _client.from('event_participants').upsert({
      'event_id': invitation.eventId,
      'user_id': userId,
      'email': email.toLowerCase(),
      'role': invitation.role.name,
      'invite_status': InviteStatus.accepted.name,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
    });
    await _client
        .from('invitations')
        .update({'status': InviteStatus.accepted.name}).eq('id', invitation.id);

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
    await _client
        .from('invitations')
        .update({'status': InviteStatus.rejected.name}).eq('id', invitation.id);
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

  /// Records the invitee's answer and tells the inviter, in both places the
  /// Notifications screen reads from.
  Future<void> _notifyInviter({
    required String inviterId,
    required String eventId,
    required String eventTitle,
    required String responderEmail,
    required bool accepted,
    String? responderName,
  }) async {
    // Inviting yourself is possible when one person owns two accounts; there is
    // no point notifying them about their own action.
    if (inviterId.isEmpty) return;

    final label = eventTitle.isEmpty ? 'your countdown' : '“$eventTitle”';
    final who = (responderName?.trim().isNotEmpty ?? false)
        ? responderName!
        : responderEmail;

    try {
      await _client.from('responses').insert({
        'recipient_id': inviterId,
        'event_id': eventId,
        'event_title': eventTitle.isEmpty ? 'your countdown' : eventTitle,
        'responder_email': responderEmail.toLowerCase(),
        if (responderName != null) 'responder_name': responderName,
        'accepted': accepted,
      });
    } catch (_) {
      // The response row is a courtesy; never fail the user's action on it.
    }

    await _notify(
      userId: inviterId,
      title: accepted ? '$who joined $label' : '$who declined $label',
      body: accepted
          ? 'They can now follow this countdown.'
          : 'They chose not to follow this countdown.',
      kind: NotificationKind.invitation,
    );
  }

  Future<void> updateParticipantRole({
    required String eventId,
    required String actorId,
    required Participant participant,
    required ParticipantRole role,
  }) async {
    await _client
        .from('event_participants')
        .update({'role': role.name})
        .eq('event_id', eventId)
        .eq('user_id', participant.userId);
  }

  // ---------------------------------------------------------------------------
  // Writes - circles
  // ---------------------------------------------------------------------------

  /// Creates a circle. The owner is added as a member straight after, so the
  /// circle always has someone who can read it.
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

    final Map<String, dynamic> created;
    try {
      created = await _client
          .from('circles')
          .insert({
            'name': name.trim(),
            'owner_id': ownerId,
            'is_couple': isCouple,
            if (emoji != null) 'emoji': emoji,
          })
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }

    final circleId = created['id'] as String;

    // The owner is a member AND the owner: without this row the circle would
    // exist but nobody could read it.
    await _client.from('circle_members').insert({
      'circle_id': circleId,
      'user_id': ownerId,
      'email': ownerEmail.toLowerCase(),
      'role': 'owner',
      if (ownerName != null) 'display_name': ownerName,
      if (ownerPhotoUrl != null) 'photo_url': ownerPhotoUrl,
    });

    return Circle(
      id: circleId,
      name: name.trim(),
      ownerId: ownerId,
      createdAt: DateTime.now(),
      emoji: emoji,
      isCouple: isCouple,
      memberIds: [ownerId],
    );
  }

  /// Invites an email into a circle.
  ///
  /// Always a pending invitation rather than an instant join: joining a
  /// standing group should be the invitee's choice, in contrast to a couple
  /// circle, which is deliberately automatic.
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
    if (inviterEmail != null && inviterEmail.trim().toLowerCase() == target) {
      throw const DataFailure(cannotInviteSelfMessage);
    }

    // Hydrate members when the caller only had the circle row — the duplicate
    // and self checks below need something to compare against.
    var members = circle.members;
    if (members.isEmpty) {
      final rows = await _client
          .from('circle_members')
          .select()
          .eq('circle_id', circle.id);
      members = rows.map((r) => CircleMember.fromRow(r)).toList();
    }
    if (members.any((m) => m.userId == inviterId && m.email == target)) {
      throw const DataFailure(cannotInviteSelfMessage);
    }
    if (members.any((m) => m.email == target)) {
      throw DataFailure('$target is already in “${circle.name}”.');
    }

    final match = await lookupUserByEmail(target);
    final inviteeId = match?['id'] as String?;
    if (inviteeId != null && inviteeId == inviterId) {
      throw const DataFailure(cannotInviteSelfMessage);
    }

    try {
      await _client.from('circle_invitations').insert({
        'circle_id': circle.id,
        'invited_by': inviterId,
        if (inviterName != null) 'invited_by_name': inviterName,
        'invitee_email': target,
        if (inviteeId != null) 'invitee_id': inviteeId,
        'circle_name': circle.name,
        'is_couple': circle.isCouple,
        'role': role.name,
      });
    } on PostgrestException catch (error) {
      throw DataFailure(_describe(error));
    }

    if (inviteeId != null && inviteeId.isNotEmpty) {
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

  /// Joins the circle an invitation points at.
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

    await _client.from('circle_members').upsert({
      'circle_id': invitation.circleId,
      'user_id': userId,
      'email': email.toLowerCase(),
      'role': 'member',
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
    });
    await _client
        .from('circle_invitations')
        .update({'status': InviteStatus.accepted.name}).eq('id', invitation.id);

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

  Future<void> rejectCircleInvitation(CircleInvitation invitation) async {
    await _client
        .from('circle_invitations')
        .update({'status': InviteStatus.rejected.name}).eq('id', invitation.id);
  }

  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    await _client
        .from('circle_members')
        .delete()
        .eq('circle_id', circleId)
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Notes, profile, lookup
  // ---------------------------------------------------------------------------

  Future<void> addNote({
    required String eventId,
    required String userId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    await _client.from('event_notes').insert({
      'event_id': eventId,
      'user_id': userId,
      'text': text.trim(),
    });
  }

  /// Syncs the user's public profile so an email lookup can resolve an address
  /// to an account without reading the auth record.
  Future<void> syncUserProfile(AppUser user) async {
    if (user.id.isEmpty || user.email.isEmpty) return;
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email.toLowerCase(),
        if (user.displayName != null) 'full_name': user.displayName,
        if (user.photoUrl != null) 'avatar_url': user.photoUrl,
      });
    } catch (_) {
      // Best-effort.
    }
  }

  /// Turns an email address into an account, if one exists.
  ///
  /// Matches on the lowercased email in `profiles`. Returns the row, or null.
  Future<Map<String, dynamic>?> lookupUserByEmail(String email) async {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('email', normalised)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  /// A short, shareable summary of a countdown.
  static String shareText(CountdownEvent event) {
    final remaining = remainingUntil(event.at);
    final phrase = describeRemaining(remaining);
    return '${event.title} — ${formatMomentFull(event.at)}\n'
        '${remaining.isPast ? 'It has arrived.' : '$phrase to go.'}';
  }

  /// Sends one inbox notification, swallowing any failure: the write it
  /// accompanies has already succeeded, so the inbox line is a courtesy.
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

  /// Turns a PostgREST error into a sentence worth showing a user.
  static String _describe(PostgrestException error) {
    switch (error.code) {
      case '42P01':
        return 'The database tables are missing. Run supabase/schema.sql.';
      case '42501':
        return 'You do not have permission to do that.';
      case '23505':
        return 'That already exists.';
      case '23503':
        return 'That refers to something that no longer exists.';
      default:
        return error.message;
    }
  }
}
