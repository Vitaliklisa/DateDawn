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

  factory Participant.fromMap(String userId, Map<String, dynamic> map) {
    return Participant(
      userId: userId,
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
      );

  String get initials {
    final source =
        (displayName?.trim().isNotEmpty ?? false) ? displayName! : email;
    if (source.isEmpty) return 'U';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
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

  bool get isShared =>
      participants.isNotEmpty || sharedWithCircleIds.isNotEmpty;

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

  /// Everyone except the signed-in user, for the "shared with" line.
  List<Participant> others(String? userId) =>
      participants.where((p) => p.userId != userId).toList();

  factory CountdownEvent.fromDoc(String id, Map<String, dynamic> map) {
    final rawParticipants = map['participants'];
    final rawNotes = map['notes'];
    final rawCircles = map['sharedWithCircleIds'];
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
  // Firestore Timestamp, without importing cloud_firestore into the model layer.
  try {
    final dynamic ts = value;
    final dynamic millis = ts.millisecondsSinceEpoch;
    if (millis is int) {
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
  } catch (_) {
    // Not a Timestamp — fall through.
  }
  return null;
}
