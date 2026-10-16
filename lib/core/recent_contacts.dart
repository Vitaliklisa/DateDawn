import 'models.dart';

/// Someone the signed-in user has invited before — a circle member or a
/// countdown collaborator — kept so the invite field can suggest them.
///
/// **Why this exists.** Typing a full email address to invite the same person
/// again is the most repetitive thing in the app. A circle already remembers its
/// people, but a countdown's invite field did not, so the second time you
/// invited your partner or your best friend you typed the address out again.
///
/// The list is derived from what the app already knows — the people you have
/// actually invited — rather than from the device's address book. That keeps it
/// working with no extra permission prompt, and means the suggestions are people
/// who can actually be invited (they already have an account).
///
/// [lastInvitedAt] is what orders the suggestions: whoever you invited most
/// recently is offered first, so the person you just added to the last countdown
/// is a single tap away on the next one.
class RecentContact {
  const RecentContact({
    required this.userId,
    required this.email,
    required this.lastInvitedAt,
    this.displayName,
    this.photoUrl,
    this.inviteCount = 1,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime lastInvitedAt;

  /// How many times this person has been invited. Ties in the recency order are
  /// broken by this, so someone invited repeatedly floats above a one-off.
  final int inviteCount;

  /// What the suggestion row reads: the name when there is one, the address
  /// otherwise.
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

  /// Whether this contact matches what has been typed so far.
  ///
  /// Matched against the name and the address, case-insensitively and on any
  /// substring, so "fri" finds "Friedrich" and "fried@…" alike — the way a search
  /// box is expected to behave rather than requiring a prefix.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return label.toLowerCase().contains(needle) ||
        email.toLowerCase().contains(needle);
  }

  factory RecentContact.fromMap(String userId, Map<String, dynamic> map) =>
      RecentContact(
        userId: userId.isNotEmpty ? userId : ((map['userId'] as String?) ?? ''),
        email: ((map['email'] as String?) ?? '').toLowerCase(),
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        lastInvitedAt: _date(map['lastInvitedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        inviteCount: (map['inviteCount'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'lastInvitedAt': lastInvitedAt.toIso8601String(),
        'inviteCount': inviteCount,
      };

  /// The same contact, moved to "now" and counted once more.
  ///
  /// Called each time the person is invited again, which is what keeps the
  /// ordering meaningful: the list is sorted by [lastInvitedAt], so without this
  /// a contact you invite daily would keep its original position.
  RecentContact touched(DateTime at) => RecentContact(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        lastInvitedAt: at,
        inviteCount: inviteCount + 1,
      );

  /// Merges fresher profile fields in without disturbing the ordering.
  RecentContact withProfile({String? name, String? photo}) => RecentContact(
        userId: userId,
        email: email,
        displayName: name ?? displayName,
        photoUrl: photo ?? photoUrl,
        lastInvitedAt: lastInvitedAt,
        inviteCount: inviteCount,
      );

  /// The invite-side representation, so a suggestion can be passed straight to
  /// `inviteByEmail`.
  InvitationRecipient toRecipient() => InvitationRecipient(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}

/// Shared date parsing for a Firestore `Timestamp`, an ISO string or a
/// `DateTime`. Duplicated from the other model files because each of them keeps
/// its helper file-private and deliberately avoids a Firestore import.
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
