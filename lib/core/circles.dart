import 'models.dart';

/// A named group of people you count down with — family, a friend group, a
/// team, or a couple.
///
/// The point of a circle is that you invite someone **once**. After that,
/// sharing any future countdown with the circle takes one tap and no email
/// address typing, which is what makes the app usable for the recurring case
/// (annual trips, a partner, a close friend group) rather than only one-offs.
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.memberIds = const [],
    this.members = const [],
    this.emoji,
    this.isCouple = false,
  });

  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final String? emoji;

  /// A couple circle behaves differently: countdowns created in it are shared
  /// with the partner automatically, with no invitation to accept. See
  /// `EventRepository.createEvent`.
  final bool isCouple;

  /// Uids of accepted members. Denormalised onto the circle document so a
  /// security rule can check membership on a single document read, without
  /// fanning out to a subcollection it has no permission to see.
  final List<String> memberIds;

  /// Hydrated member rows, filled in by the repository where available.
  final List<CircleMember> members;

  bool contains(String? userId) =>
      userId != null && (ownerId == userId || memberIds.contains(userId));

  bool isOwner(String? userId) => userId != null && ownerId == userId;

  factory Circle.fromDoc(String id, Map<String, dynamic> map,
      {List<CircleMember> members = const []}) {
    final rawIds = map['memberIds'];
    return Circle(
      id: id,
      name: (map['name'] as String?) ?? 'Circle',
      ownerId: (map['ownerId'] as String?) ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      emoji: map['emoji'] as String?,
      isCouple: (map['isCouple'] as bool?) ?? false,
      memberIds:
          rawIds is List ? rawIds.whereType<String>().toList() : const [],
      members: members,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
        'isCouple': isCouple,
        if (emoji != null) 'emoji': emoji,
        'memberIds': memberIds,
      };

  /// Builds from a Supabase `circles` row.
  ///
  /// `memberIds` is not a column in Postgres — membership lives in
  /// `circle_members`. The owner is always a member, so it is seeded here; the
  /// UI reads the full list separately through `watchCircleMembers`.
  factory Circle.fromRow(Map<String, dynamic> row) {
    final ownerId = (row['owner_id'] as String?) ?? '';
    return Circle(
      id: (row['id'] as String?) ?? '',
      name: (row['name'] as String?) ?? 'Circle',
      ownerId: ownerId,
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      emoji: row['emoji'] as String?,
      isCouple: (row['is_couple'] as bool?) ?? false,
      memberIds: [if (ownerId.isNotEmpty) ownerId],
    );
  }

  Circle copyWith({
    String? name,
    String? emoji,
    List<String>? memberIds,
    List<CircleMember>? members,
  }) =>
      Circle(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId,
        createdAt: createdAt,
        emoji: emoji ?? this.emoji,
        isCouple: isCouple,
        memberIds: memberIds ?? this.memberIds,
        members: members ?? this.members,
      );
}

/// One person inside a circle.
class CircleMember {
  const CircleMember({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isOwner = false,
    this.joinedAt,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isOwner;
  final DateTime? joinedAt;

  factory CircleMember.fromMap(String userId, Map<String, dynamic> map) =>
      CircleMember(
        userId: userId,
        email: ((map['email'] as String?) ?? '').toLowerCase(),
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        isOwner: (map['isOwner'] as bool?) ?? false,
        joinedAt: _date(map['joinedAt']),
      );

  /// Builds from a Supabase `circle_members` row.
  factory CircleMember.fromRow(Map<String, dynamic> row) => CircleMember(
        userId: (row['user_id'] as String?) ?? '',
        email: ((row['email'] as String?) ?? '').toLowerCase(),
        displayName: row['display_name'] as String?,
        photoUrl: row['photo_url'] as String?,
        isOwner: row['role'] == 'owner',
        joinedAt: _date(row['joined_at']),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'isOwner': isOwner,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  String get label =>
      (displayName?.trim().isNotEmpty ?? false) ? displayName! : email;

  String get initials {
    final source = label;
    if (source.isEmpty) return 'U';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// An invite to a **circle** (a standing group) rather than to a single
/// countdown.
///
/// Kept separate from `Invitation` so the two flows can diverge: a countdown
/// invite is about one event, a circle invite is about joining a group whose
/// future events you will see automatically.
class CircleInvitation {
  const CircleInvitation({
    required this.id,
    required this.circleId,
    required this.invitedBy,
    required this.inviteeEmail,
    required this.createdAt,
    required this.expiresAt,
    required this.circleName,
    this.invitedByName,
    this.status = InviteStatus.pending,
    this.isCouple = false,
  });
  final String id;
  final String circleId;
  final String invitedBy;
  final String? invitedByName;
  final String inviteeEmail;
  final String circleName;
  final bool isCouple;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory CircleInvitation.fromDoc(String id, Map<String, dynamic> map) =>
      CircleInvitation(
        id: id,
        circleId: (map['circleId'] as String?) ?? '',
        invitedBy: (map['invitedBy'] as String?) ?? '',
        invitedByName: map['invitedByName'] as String?,
        inviteeEmail: ((map['inviteeEmail'] as String?) ?? '').toLowerCase(),
        circleName: (map['circleName'] as String?) ?? 'a circle',
        isCouple: (map['isCouple'] as bool?) ?? false,
        status: InviteStatus.fromWire(map['status']),
        createdAt: _date(map['createdAt']) ?? DateTime.now(),
        expiresAt: _date(map['expiresAt']) ??
            DateTime.now().add(const Duration(days: 30)),
      );

  Map<String, dynamic> toMap() => {
        'circleId': circleId,
        'invitedBy': invitedBy,
        if (invitedByName != null) 'invitedByName': invitedByName,
        'inviteeEmail': inviteeEmail,
        'circleName': circleName,
        'isCouple': isCouple,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  /// Builds from a Supabase `circle_invitations` row.
  factory CircleInvitation.fromRow(Map<String, dynamic> row) =>
      CircleInvitation(
        id: (row['id'] as String?) ?? '',
        circleId: (row['circle_id'] as String?) ?? '',
        invitedBy: (row['invited_by'] as String?) ?? '',
        invitedByName: row['invited_by_name'] as String?,
        inviteeEmail: ((row['invitee_email'] as String?) ?? '').toLowerCase(),
        circleName: (row['circle_name'] as String?) ?? 'a circle',
        isCouple: (row['is_couple'] as bool?) ?? false,
        status: InviteStatus.fromWire(row['status']),
        createdAt: _date(row['created_at']) ?? DateTime.now(),
        expiresAt: _date(row['expires_at']) ??
            DateTime.now().add(const Duration(days: 30)),
      );
}

/// What the inviter sees about an invitation they sent.
///
/// This is the feedback half of the request: when someone accepts or declines,
/// the person who invited them finds out — and it is written as a one-way
/// notification so the inviter is not required to be online when the answer
/// arrives.
class InvitationResponse {
  const InvitationResponse({
    required this.id,
    required this.recipientId,
    required this.eventId,
    required this.eventTitle,
    required this.responderEmail,
    required this.accepted,
    required this.respondedAt,
    this.responderName,
    this.read = false,
  });

  final String id;

  /// The user who *sent* the invitation — the one who should be told.
  final String recipientId;

  final String eventId;
  final String eventTitle;
  final String responderEmail;
  final String? responderName;
  final bool accepted;
  final DateTime respondedAt;
  final bool read;

  /// The sentence shown in the notifications list.
  String get message {
    final who = (responderName?.trim().isNotEmpty ?? false)
        ? responderName!
        : responderEmail;
    return accepted
        ? '$who joined “$eventTitle”.'
        : '$who declined “$eventTitle”.';
  }

  factory InvitationResponse.fromDoc(String id, Map<String, dynamic> map) =>
      InvitationResponse(
        id: id,
        recipientId: (map['recipientId'] as String?) ?? '',
        eventId: (map['eventId'] as String?) ?? '',
        eventTitle: (map['eventTitle'] as String?) ?? 'your countdown',
        responderEmail:
            ((map['responderEmail'] as String?) ?? '').toLowerCase(),
        responderName: map['responderName'] as String?,
        accepted: (map['accepted'] as bool?) ?? false,
        respondedAt: _date(map['respondedAt']) ?? DateTime.now(),
        read: (map['read'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'responderEmail': responderEmail,
        if (responderName != null) 'responderName': responderName,
        'accepted': accepted,
        'respondedAt': respondedAt.toIso8601String(),
        'read': read,
      };

  /// Builds from a Supabase `responses` row.
  factory InvitationResponse.fromRow(Map<String, dynamic> row) =>
      InvitationResponse(
        id: (row['id'] as String?) ?? '',
        recipientId: (row['recipient_id'] as String?) ?? '',
        eventId: (row['event_id'] as String?) ?? '',
        eventTitle: (row['event_title'] as String?) ?? 'your countdown',
        responderEmail:
            ((row['responder_email'] as String?) ?? '').toLowerCase(),
        responderName: row['responder_name'] as String?,
        accepted: (row['accepted'] as bool?) ?? false,
        respondedAt: _date(row['responded_at']) ?? DateTime.now(),
        read: (row['is_read'] as bool?) ?? false,
      );
}

/// Shared date parsing — Firestore `Timestamp`, ISO string, or `DateTime`.
/// Duplicated from `models.dart`'s private helper because that one is
/// file-private and this file is deliberately free of a Firestore import.
DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  try {
    final dynamic ts = value;
    final dynamic millis = ts.millisecondsSinceEpoch;
    if (millis is int) {
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
  } catch (_) {
    // Not a Timestamp.
  }
  return null;
}
