import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
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
  required String eventId,
}) async {
  if (participant.isCircle) return false;
  final blocked = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _BlockUserSheet(
      participant: participant,
      eventId: eventId,
    ),
  );
  return blocked ?? false;
}

class _BlockUserSheet extends ConsumerStatefulWidget {
  const _BlockUserSheet({
    required this.participant,
    required this.eventId,
  });

  final Participant participant;
  final String eventId;

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
    // Resolve the messenger from the ROOT context, before the sheet is popped.
    //
    // The sheet is a modal route; `ScaffoldMessenger.of(context)` captured from
    // its builder is a messenger that dies with the route. Popping first and
    // then showing the success snackbar on it dropped the success toast while
    // still letting a later failure toast through -- which is how a block that
    // worked could look like "nothing happened" or, worse, end with a stray
    // permission message. Resolving it from the app's root messenger keeps it
    // alive across the pop.
    final messenger = ScaffoldMessenger.of(
      rootNavigatorKey.currentContext ?? context,
    );
    try {
      await ref.read(eventRepositoryProvider).blockUser(
            userId: me.id,
            targetUid: widget.participant.userId,
            targetEmail: widget.participant.email,
            targetDisplayName: widget.participant.displayName,
            targetPhotoUrl: widget.participant.photoUrl,
          );
    } catch (error) {
      // Only a failure of the block itself reaches here. Every cleanup step
      // inside `blockUser` is best-effort and never throws, so this message is
      // about the block, not about a shared countdown the blocker could not
      // administer.
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_blockFailureMessage(error)),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (!mounted) return;
    // The block succeeded. Re-read the blocked list now, so Settings → Blocked
    // people shows this person the moment it is opened, and invalidate the
    // same feeds the block pruned (participants, invitations, notes). The
    // writes are done; this is what makes the UI agree with them.
    final container = ProviderScope.containerOf(context, listen: false);
    final repository = ref.read(eventRepositoryProvider);
    container.invalidate(blockedUsersProvider);
    container.invalidate(invitationsProvider);
    container.invalidate(eventsProvider);
    container.invalidate(participantsProvider(widget.eventId));
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text('$_who is blocked.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            unawaited(
              _undoBlock(
                container: container,
                repository: repository,
                messenger: messenger,
                userId: me.id,
                targetUid: widget.participant.userId,
                eventId: widget.eventId,
                who: _who,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _undoBlock({
    required ProviderContainer container,
    required EventRepository repository,
    required ScaffoldMessengerState messenger,
    required String userId,
    required String targetUid,
    required String eventId,
    required String who,
  }) async {
    try {
      await repository.unblockUser(userId: userId, targetUid: targetUid);
      container.invalidate(blockedUsersProvider);
      container.invalidate(invitationsProvider);
      container.invalidate(eventsProvider);
      container.invalidate(participantsProvider(eventId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$who is unblocked. Countdown access was not restored.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not undo block for $targetUid: $error');
      debugPrintStack(stackTrace: stackTrace);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not undo block. Please try again.')),
      );
    }
  }

  /// What to tell the user when the block write itself was refused.
  ///
  /// Split out so the "we could not save your block" case never gets the
  /// generic "you do not have permission to do that" wording that used to
  /// appear for an unrelated cleanup refusal. A permission error on the block
  /// row means the session is not what the rules expect (a signed-out tab, an
  /// account switch), and that is what is said.
  String _blockFailureMessage(Object error) {
    return switch (error) {
      DataFailure(:final message) => message,
      FirebaseException(code: 'permission-denied') =>
        'Your block could not be saved. Sign in again and retry.',
      FirebaseException(code: 'unavailable') =>
        'No connection. Check your network and try again.',
      _ => 'Could not block $_who. Please try again.',
    };
  }
}
