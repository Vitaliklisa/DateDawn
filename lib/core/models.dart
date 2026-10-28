import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Which powers a collaborator has on a shared event.
///
/// Mirrors the `participantRoleSchema` enum in the web app (`admin`, `editor`,
/// `viewer`) and is enforced server-side by `firestore.rules`.
enum ParticipantRole {
  admin,
  editor,
  viewer;

  static ParticipantRole fromWire(Object? value) {
    switch (value) {
      case 'admin':
        return ParticipantRole.admin;
      case 'editor':
        return ParticipantRole.editor;
      default:
        return ParticipantRole.viewer;
    }
  }

  /// Admins can invite, rename, reschedule and delete. Editors can only
  /// rename/reschedule. Viewers can only look at the countdown.
  bool get canEdit =>
      this == ParticipantRole.admin || this == ParticipantRole.editor;
  bool get canManage => this == ParticipantRole.admin;

  /// How much authority a role carries. Admin > editor > viewer.
  ///
  /// This is the one ordering the whole app reasons about — who may change a
  /// role, and up to which role — so it lives on the enum rather than being
  /// re-derived at each call site. A second ordering elsewhere (or a second
  /// "manager" concept for role changes specifically) would drift from this one.
  int get authorityRank => switch (this) {
        ParticipantRole.admin => 2,
        ParticipantRole.editor => 1,
        ParticipantRole.viewer => 0,
      };

  /// Whether the management powers of this role are at least [other]'s.
  ///
  /// `admin.grantsAtLeast(editor)` is true; `editor.grantsAtLeast(admin)` is
  /// false. Used to stop anyone granting more authority than they hold, and to
  /// stop anyone altering a role as or more powerful than their own.
  bool grantsAtLeast(ParticipantRole other) =>
      authorityRank >= other.authorityRank;

  /// What this role may do, in the words the UI shows.
  String get description => switch (this) {
        ParticipantRole.admin =>
          'Can invite people, change roles, edit the countdown and remove '
              'collaborators.',
        ParticipantRole.editor =>
          'Can edit the title, description and date. Cannot manage people.',
        ParticipantRole.viewer => 'Can only follow the countdown.',
      };

  /// Human label — "Viewer", "Editor", "Admin".
  String get label => switch (this) {
        ParticipantRole.admin => 'Admin',
        ParticipantRole.editor => 'Editor',
        ParticipantRole.viewer => 'Viewer',
      };
}

/// Where a collaborator stands on an invitation they received.
///
/// `rejected` and `declined` are deliberately different. A `rejected` row is one
/// an admin removed or an invitation that was cancelled — the person never
/// engaged with it. A `declined` row is someone who *answered no*, and it is
/// kept on the list on purpose: the countdown owner should be able to see who
/// said no rather than have them silently vanish, and the person who declined
/// should be able to change their mind.
///
/// `reopened` is the state between "they changed their mind" and the answer they
/// give next: a declined row that has been put back in front of the invitee.
/// Without it the accept rule would have to admit a write on a `declined` row,
/// which would let any admin flip someone's answer without asking them.
enum InviteStatus {
  pending,
  accepted,
  declined,
  rejected,
  reopened;

  static InviteStatus fromWire(Object? value) {
    switch (value) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'rejected':
        return InviteStatus.rejected;
      case 'reopened':
        return InviteStatus.reopened;
      default:
        return InviteStatus.pending;
    }
  }

  /// Whether the invitee still has a decision to make.
  bool get isAwaitingAnswer =>
      this == InviteStatus.pending || this == InviteStatus.reopened;

  /// Whether this row counts as unsettled for the inviter's "waiting on" list.
  bool get isSettled => !isAwaitingAnswer;
}

/// What a participant row actually represents.
///
/// A countdown can be shared with a whole circle, which is recorded as one
/// synthetic row rather than one row per member. That row is not a person and
/// must not be shown as one.
enum ParticipantKind {
  person,
  circle;

  static ParticipantKind fromWire(Object? value) =>
      value == 'circle' ? ParticipantKind.circle : ParticipantKind.person;
}

/// Someone who can see an event alongside its creator.
class Participant {
  const Participant({
    required this.userId,
    required this.email,
    required this.role,
    required this.inviteStatus,
    this.displayName,
    this.photoUrl,
    this.joinedAt,
    this.kind = ParticipantKind.person,
    this.circleName,
  });

  final String userId;
  final String email;
  final ParticipantRole role;
  final InviteStatus inviteStatus;
  final String? displayName;
  final String? photoUrl;
  final DateTime? joinedAt;

  /// Whether this row is a real account or a placeholder standing in for a
  /// whole circle that was shared with.
  ///
  /// `createEvent` writes a synthetic `participants/circle:{id}` row when a
  /// countdown is shared to a circle. It carries **no email and no name**, so
  /// rendered naively it drew as a nameless person with a fallback "U" avatar —
  /// a row that identifies nobody sitting in a list of named people. This flag
  /// is what lets the UI say "shared with Friends (4)" instead.
  final ParticipantKind kind;

  /// Set only on a [ParticipantKind.circle] row.
  final String? circleName;

  bool get isCircle => kind == ParticipantKind.circle;

  /// Whether the person has actually answered, as opposed to a circle
  /// placeholder which has no answer to give.
  bool get hasAnswered => !isCircle && inviteStatus.isSettled;

  /// Reads one participant row.
  ///
  /// [userId] is the **document id**, which is the authority: rows are written
  /// at `events/{id}/participants/{uid}`. The body also carries a `userId`
  /// field, because `watchEvents` discovers shared countdowns with a
  /// collection-group query on that field and a document id is not queryable
  /// that way. The body value is used when present and the id when not, so a
  /// row written by an older build still parses.
  factory Participant.fromMap(String userId, Map<String, dynamic> map) {
    final bodyId = map['userId'];
    return Participant(
      userId: userId.isNotEmpty ? userId : (bodyId is String ? bodyId : ''),
      email: (map['email'] as String?) ?? '',
      role: ParticipantRole.fromWire(map['role']),
      inviteStatus: InviteStatus.fromWire(map['inviteStatus']),
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      joinedAt: _parseDate(map['joinedAt']),
      kind: ParticipantKind.fromWire(map['kind']),
      circleName: map['circleName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        // Mirrors what the repository writes: the uid both as the document id
        // and as a body field, because the collection-group visibility query
        // filters on the field.
        'userId': userId,
        'email': email,
        'role': role.name,
        'inviteStatus': inviteStatus.name,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  Participant copyWith({
    ParticipantRole? role,
    InviteStatus? inviteStatus,
  }) =>
      Participant(
        userId: userId,
        email: email,
        role: role ?? this.role,
        inviteStatus: inviteStatus ?? this.inviteStatus,
        displayName: displayName,
        photoUrl: photoUrl,
        joinedAt: joinedAt,
        // Carried over, not dropped: without these, `copyWith` turned a circle
        // placeholder into a nameless "person" row — which the role policy then
        // treated as someone whose role could be changed.
        kind: kind,
        circleName: circleName,
      );

  /// See `CircleMember.initials`: slicing the untrimmed label produced a tile
  /// showing a stray letter for a display name with a leading space.
  String get initials {
    final name = displayName?.trim();
    final source = (name != null && name.isNotEmpty) ? name : email.trim();
    final parts =
        source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '?';
  }
}

/// Someone to invite to a countdown the moment it is created.
///
/// Carries the email as well as the uid because an `invitations` document — the
/// only thing the invitee's inbox streams — is addressed and matched by email.
/// A uid alone is not enough to write one.
class InvitationRecipient {
  const InvitationRecipient({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = ParticipantRole.viewer,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final ParticipantRole role;
}

/// Someone this user has blocked.
///
/// Required by Google Play's user-generated-content policy: an app where people
/// can send each other invitations and notes (1:1 interaction) must let a person
/// block another person **in-app**, and blocking has to actually cut the
/// connection — not hide a name in a list.
///
/// Blocking is one-directional and private: only the blocker can read the row,
/// the blocked person is never told, and nothing about it is visible to anyone
/// else. Unblocking deletes the row.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.blockedAt,
  });

  /// The blocked account's uid — also the document id under
  /// `users/{me}/blocked/{uid}`, so one person can only ever be blocked once.
  final String userId;

  /// The account's email, as it was when the block was made. Also what incoming
  /// invitations are matched against, so an invite sent to this address is
  /// dropped even if the uid changed.
  final String email;

  final String? displayName;
  final String? photoUrl;
  final DateTime? blockedAt;

  /// The field every block row carries, and the one the list query filters on.
  ///
  /// A rule that has to `exists()` the owner's profile document cannot be
  /// evaluated for a collection query, so the read is authorised by this plain
  /// field comparison instead. See `EventRepository.watchBlockedUsers`.
  static const String activeField = 'active';

  /// What to call this person on screen. Never an empty label, and never an
  /// email shown as if it were a name.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.isNotEmpty ? email : 'Blocked user';
  }

  factory BlockedUser.fromMap(String id, Map<String, dynamic> map) {
    return BlockedUser(
      userId: id,
      email: ((map['email'] as String?) ?? '').toLowerCase(),
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      blockedAt: _parseDate(map['blockedAt']),
    );
  }
}

/// The answer to "may this role be changed?", with the sentence to show when
/// it may not.
class RoleChangeCheck {
  const RoleChangeCheck.allowed()
      : allowed = true,
        message = null;

  const RoleChangeCheck.denied(this.message) : allowed = false;

  final bool allowed;
  final String? message;
}

/// A short comment left on an event by a participant.
class EventNote {
  const EventNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EventNote.fromMap(Map<String, dynamic> map) => EventNote(
        id: (map['id'] as String?) ?? '',
        userId: (map['userId'] as String?) ?? '',
        text: (map['text'] as String?) ?? '',
        createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// A countdown: one moment in the future, optionally shared with others.
class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.at,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.participants = const [],
    this.notes = const [],
    this.circleId,
    this.sharedWithCircleIds = const [],
    this.sharedWithMemberIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime at;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<Participant> participants;
  final List<EventNote> notes;

  /// If set, this countdown belongs to a circle and is visible to every member.
  /// A couple circle supersedes it — see `sharedWithCircleIds`.
  final String? circleId;

  /// Every circle this countdown is shared with.
  ///
  /// A countdown keeps its own `circleId` for the common single-circle case,
  /// but a couple who are each in their own family circle can share one
  /// countdown with both, which is why this is a list.
  final List<String> sharedWithCircleIds;

  /// The uids of every member of every circle in [sharedWithCircleIds],
  /// denormalised onto the countdown.
  ///
  /// **Why this is duplicated.** The list of circle-shared countdowns is
  /// discovered with a Firestore collection query. A security rule that has to
  /// look the circle up (`get(circles/{id})` to read its `memberIds`) cannot be
  /// evaluated for a query, because the rule engine cannot resolve a
  /// cross-collection read for every candidate row — Firestore refuses the
  /// whole query with `permission-denied`. That is exactly what happened: the
  /// countdown was shared, the partner was a member, and the query that would
  /// have shown it to them failed silently on every device.
  ///
  /// Carrying the uids on the event makes the rule a plain field comparison
  /// (`uid() in data.sharedWithMemberIds`), which Firestore can prove for a
  /// query. It is maintained alongside [sharedWithCircleIds] whenever a
  /// countdown is shared or a circle gains a member.
  final List<String> sharedWithMemberIds;

  bool get isShared =>
      participants.isNotEmpty ||
      sharedWithCircleIds.isNotEmpty ||
      sharedWithMemberIds.isNotEmpty;

  bool get isPast => !at.isAfter(DateTime.now());

  /// The signed-in user's own row in `participants`, if they have one.
  Participant? participantFor(String? userId) {
    if (userId == null) return null;
    for (final p in participants) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  /// The role the signed-in user acts with. The creator is always an admin,
  /// even before their participant row has been written.
  ParticipantRole roleFor(String? userId) {
    if (userId != null && userId == createdBy) return ParticipantRole.admin;
    return participantFor(userId)?.role ?? ParticipantRole.viewer;
  }

  bool canEdit(String? userId) => roleFor(userId).canEdit;
  bool canManage(String? userId) => roleFor(userId).canManage;

  /// Whether [userId] may change [target]'s role to [role].
  ///
  /// The policy, in one place so the screen, the repository and the rules all
  /// describe the same thing:
  ///
  /// * only someone who can manage the countdown (an admin, which includes
  ///   its creator) may change anyone's role;
  /// * nobody may change their own role — that is how someone hands themselves
  ///   more power, or quietly gives it away;
  /// * the creator keeps ownership whatever their row says, so their role is
  ///   not a lever anyone gets to pull;
  /// * the role must actually be a change;
  /// * the caller must be an admin, and may only grant authority up to their
  ///   own. "Admin" *is* the managing role here, so an admin may act on any row
  ///   — including another admin's — while everyone else is stopped from
  ///   managing at all. That is also what stops a person who has just been
  ///   demoted from handing the admin role straight back: their own role is
  ///   re-read from the database before the write, so they are no longer an
  ///   admin when the check runs. The creator is exempt from the rank question
  ///   because they are the owner, not a rank.
  ///
  /// This mirrors `roleChangeAllowed` in `firestore.rules`.
  RoleChangeCheck checkRoleChange({
    required String? actorId,
    required Participant target,
    required ParticipantRole role,
  }) {
    final actorRole = roleFor(actorId);
    if (!actorRole.canManage) {
      return const RoleChangeCheck.denied(
          'Only an admin of this countdown can change roles.');
    }
    if (actorId == null || actorId == target.userId) {
      return const RoleChangeCheck.denied('You cannot change your own role.');
    }
    if (target.userId == createdBy) {
      return const RoleChangeCheck.denied(
          'The person who created this countdown keeps ownership.');
    }
    if (target.isCircle) {
      return const RoleChangeCheck.denied(
          'A circle share is managed from the circle, not here.');
    }
    if (target.role == role) {
      return const RoleChangeCheck.denied('That is already their role.');
    }
    if (!actorRole.grantsAtLeast(role)) {
      return const RoleChangeCheck.denied(
          'You cannot give someone more access than you have.');
    }
    return const RoleChangeCheck.allowed();
  }

  /// The roles [actorId] may hand to [target], in escalation order.
  ///
  /// What the "Change role" sheet offers, so an option that would be refused
  /// is never shown as a choice. Empty when the caller may not change this
  /// person's role at all.
  List<ParticipantRole> assignableRolesFor({
    required String? actorId,
    required Participant target,
  }) {
    if (target.userId == createdBy) return const [];
    return const [
      ParticipantRole.viewer,
      ParticipantRole.editor,
      ParticipantRole.admin,
    ]
        .where((role) =>
            checkRoleChange(actorId: actorId, target: target, role: role)
                .allowed)
        .toList(growable: false);
  }

  /// Everyone except the signed-in user, for the "shared with" line.
  List<Participant> others(String? userId) =>
      participants.where((p) => p.userId != userId).toList();

  factory CountdownEvent.fromDoc(String id, Map<String, dynamic> map) {
    final rawParticipants = map['participants'];
    final rawNotes = map['notes'];
    final rawCircles = map['sharedWithCircleIds'];
    final rawMembers = map['sharedWithMemberIds'];
    final circleId = map['circleId'] as String?;

    // A countdown written before circles existed, or shared with a single
    // circle, still needs to answer `sharedWithCircleIds` correctly.
    final circles = <String>{
      if (circleId != null && circleId.isNotEmpty) circleId,
      if (rawCircles is List) ...rawCircles.whereType<String>(),
    };

    return CountdownEvent(
      id: id,
      title: (map['title'] as String?) ?? 'Untitled',
      description: (map['description'] as String?) ?? '',
      at: _parseDate(map['at']) ?? DateTime.now(),
      createdBy: (map['createdBy'] as String?) ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      deletedAt: _parseDate(map['deletedAt']),
      circleId: circleId,
      sharedWithCircleIds: circles.toList(),
      sharedWithMemberIds: rawMembers is List
          ? rawMembers.whereType<String>().toList()
          : const [],
      participants: rawParticipants is Map
          ? rawParticipants.entries
              .map((e) => Participant.fromMap(
                    e.key.toString(),
                    Map<String, dynamic>.from(e.value as Map),
                  ))
              .toList()
          : const [],
      notes: rawNotes is List
          ? rawNotes
              .whereType<Map>()
              .map((n) => EventNote.fromMap(Map<String, dynamic>.from(n)))
              .toList()
          : const [],
    );
  }

  /// Only the fields a client is allowed to write — `participants` and `notes`
  /// are mutated through their own narrow updates so two devices editing at
  /// once don't clobber each other's rows.
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'at': at.toIso8601String(),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (circleId != null) 'circleId': circleId,
        if (sharedWithCircleIds.isNotEmpty)
          'sharedWithCircleIds': sharedWithCircleIds,
        // Denormalised for the circle-visibility query; see the field's doc.
        if (sharedWithMemberIds.isNotEmpty)
          'sharedWithMemberIds': sharedWithMemberIds,
      };

  CountdownEvent copyWith({
    String? title,
    String? description,
    DateTime? at,
    DateTime? updatedAt,
    List<Participant>? participants,
    List<EventNote>? notes,
    String? circleId,
    List<String>? sharedWithCircleIds,
    List<String>? sharedWithMemberIds,
  }) =>
      CountdownEvent(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        at: at ?? this.at,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        participants: participants ?? this.participants,
        notes: notes ?? this.notes,
        circleId: circleId ?? this.circleId,
        sharedWithCircleIds: sharedWithCircleIds ?? this.sharedWithCircleIds,
        sharedWithMemberIds: sharedWithMemberIds ?? this.sharedWithMemberIds,
      );
}

/// An invitation addressed to an email that has no account yet, or that the
/// inviter does not want to add straight to the participant list.
class Invitation {
  const Invitation({
    required this.id,
    required this.eventId,
    required this.invitedBy,
    required this.inviteeEmail,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.eventTitle = '',
  });

  final String id;
  final String eventId;
  final String invitedBy;
  final String inviteeEmail;
  final ParticipantRole role;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Denormalised onto the invite so the banner can name the event without a
  /// second read (and without needing permission to read the event yet).
  final String eventTitle;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory Invitation.fromDoc(String id, Map<String, dynamic> map) => Invitation(
        id: id,
        eventId: (map['eventId'] as String?) ?? '',
        invitedBy: (map['invitedBy'] as String?) ?? '',
        inviteeEmail: ((map['inviteeEmail'] as String?) ?? '').toLowerCase(),
        role: ParticipantRole.fromWire(map['role']),
        status: InviteStatus.fromWire(map['status']),
        createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
        expiresAt: _parseDate(map['expiresAt']) ??
            DateTime.now().add(const Duration(days: 30)),
        eventTitle: (map['eventTitle'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'invitedBy': invitedBy,
        'inviteeEmail': inviteeEmail,
        'role': role.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'eventTitle': eventTitle,
      };
}

/// Firestore hands back `Timestamp`s for date fields, but documents written by
/// the seed script or a test use plain ISO strings. Accept both.
DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  try {
    final dynamic ts = value;
    // Cloud Firestore's own `Timestamp`. Checked first, because its
    // `millisecondsSinceEpoch` is a *method*, not the int `DateTime` exposes —
    // the fallback below read it as a property and silently produced `null` for
    // every timestamp the app itself wrote (`blockedAt`, for one).
    if (ts is Timestamp) return ts.toDate().toLocal();
  } catch (_) {
    // No Firestore type available here — fall through.
  }
  // Any other Timestamp-shaped object, without importing cloud_firestore into
  // the model layer.
  try {
    final dynamic ts = value;
    final dynamic millis = ts.millisecondsSinceEpoch;
    if (millis is int) {
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
    if (millis is Function) {
      final dynamic result = millis();
      if (result is int) {
        return DateTime.fromMillisecondsSinceEpoch(result).toLocal();
      }
    }
  } catch (_) {
    // Not a Timestamp — fall through.
  }
  return null;
}
