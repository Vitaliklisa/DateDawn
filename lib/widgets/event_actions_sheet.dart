import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../services/event_repository.dart';
import '../widgets/share_event.dart';

/// The long-press / "Options" sheet for a countdown: open, edit, duplicate,
/// share, delete.
///
/// Actions the signed-in user has no permission for are hidden rather than
/// shown-and-disabled, so the sheet never offers something that will fail.
Future<void> showEventActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required CountdownEvent event,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _EventActionsSheet(
      event: event,
      onDeleted: onDeleted,
    ),
  );
}

class _EventActionsSheet extends ConsumerWidget {
  const _EventActionsSheet({required this.event, this.onDeleted});

  final CountdownEvent event;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final canEdit = event.canEdit(user?.id);
    final canManage = event.canManage(user?.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.isPast ? 'Passed' : 'Counting down',
                    style: TextStyle(fontSize: 12, color: colors.subtle),
                  ),
                ],
              ),
            ),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 8),
            _Action(
              icon: Icons.open_in_new_rounded,
              label: 'Open',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/event/${event.id}');
              },
            ),
            if (canEdit)
              _Action(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/event/${event.id}/edit', extra: event);
                },
              ),
            _Action(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: () {
                Navigator.of(context).pop();
                shareEvent(context, event);
              },
            ),
            if (user != null)
              _Action(
                icon: Icons.content_copy_rounded,
                label: 'Duplicate a year later',
                onTap: () async {
                  Navigator.of(context).pop();
                  await runAction(
                    context,
                    () => ref.read(eventRepositoryProvider).duplicateEvent(
                          event: event,
                          userId: user.id,
                          email: user.email,
                          displayName: user.displayName,
                          photoUrl: user.photoUrl,
                        ),
                    successMessage: 'Duplicated — open it to adjust the date.',
                  );
                },
              ),
            if (canManage) ...[
              const SizedBox(height: 6),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 6),
              _Action(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                destructive: true,
                onTap: () async {
                  // Capture what survives the sheet before closing it: once the
                  // sheet is popped this widget is gone from the tree and its
                  // `context` is unsafe to read from.
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  if (user == null) return;

                  // Confirm first, then close. Closing the sheet first used to
                  // race the dialog against the deactivated sheet context.
                  final confirmed = await _confirmDelete(context);
                  if (!confirmed) return;
                  navigator.pop();

                  try {
                    await ref.read(eventRepositoryProvider).deleteEvent(
                          event: event,
                          userId: user.id,
                        );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Countdown deleted.')),
                    );
                    onDeleted?.call();
                  } on DataFailure catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  } catch (_) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Could not delete. Try again.')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this countdown?'),
        content: const Text('The countdown cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.colors.danger,
              minimumSize: const Size(88, 42),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = destructive ? colors.danger : colors.fg;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 14.5, color: tint)),
          ],
        ),
      ),
    );
  }
}
