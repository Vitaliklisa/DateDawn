import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../services/event_repository.dart';

/// Blocking another person, from the people list on a countdown.
///
/// Google Play's user-generated-content policy requires in-app blocking for any
/// app where people can interact one-to-one — here, invitations and notes on a
/// shared countdown. The policy is not satisfied by a hidden flag: the person
/// blocking has to be told what blocking does, and has to be able to undo it.
/// This sheet is the confirming half of that; Settings → Blocked people is the
/// undo.
///
/// Returns `true` when the block was written.
Future<bool> showBlockUserSheet(
  BuildContext context, {
  required Participant participant,
}) async {
  if (participant.isCircle) return false;
  final blocked = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _BlockUserSheet(participant: participant),
  );
  return blocked ?? false;
}

class _BlockUserSheet extends ConsumerStatefulWidget {
  const _BlockUserSheet({required this.participant});

  final Participant participant;

  @override
  ConsumerState<_BlockUserSheet> createState() => _BlockUserSheetState();
}

class _BlockUserSheetState extends ConsumerState<_BlockUserSheet> {
  bool _busy = false;

  String get _who => widget.participant.displayName?.trim().isNotEmpty == true
      ? widget.participant.displayName!.trim()
      : widget.participant.email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Block $_who?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'You will stop seeing each other. They are removed from every '
              'countdown you share, invitations between you are cancelled, and '
              'they cannot invite you again. They are not told.',
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
            ),
            const SizedBox(height: 10),
            Text(
              'You can undo this any time in Settings → Blocked people.',
              style:
                  TextStyle(fontSize: 12.5, height: 1.45, color: colors.subtle),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _busy ? null : _block,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.block_rounded, size: 18),
              label: Text(_busy ? 'Blocking…' : 'Block'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _block() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(eventRepositoryProvider).blockUser(
            userId: me.id,
            targetUid: widget.participant.userId,
            targetEmail: widget.participant.email,
            targetDisplayName: widget.participant.displayName,
            targetPhotoUrl: widget.participant.photoUrl,
          );
      if (!mounted) return;
      // The block succeeded. Re-read the blocked list now, so Settings → Blocked
      // people shows this person the moment it is opened, and invalidate the
      // same feeds the block pruned (participants, invitations, notes). The
      // writes are done; this is what makes the UI agree with them.
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(invitationsProvider);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$_who is blocked.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await ref.read(eventRepositoryProvider).unblockUser(
                    userId: me.id,
                    targetUid: widget.participant.userId,
                  );
              // Unblocking changes the list too — refresh it, or Settings would
              // keep showing someone who is no longer blocked.
              ref.invalidate(blockedUsersProvider);
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      // Say what actually went wrong. A bare "Could not block" left the user
      // with no idea whether to retry, sign in, or check their connection — and
      // it hid a permission error behind the same sentence as a network drop.
      final message = switch (error) {
        DataFailure(:final message) => message,
        FirebaseException(code: 'permission-denied') =>
          'You do not have permission to do that. Make sure you are signed in, '
              'then try again.',
        FirebaseException(code: 'unavailable') =>
          'No connection. Check your network and try again.',
        _ => 'Could not block $_who. Please try again.',
      };
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}
