import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../services/event_repository.dart';
import '../widgets/share_event.dart';

/// The long-press / "Options" sheet for a countdown: open, edit, duplicate,
/// share, delete.
///
/// Delete remains visible for layout consistency, but authorization is checked
/// before confirmation and again by the repository before any write.
Future<void> showEventActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required CountdownEvent event,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _EventActionsSheet(
        event: event,
        onDeleted: onDeleted,
      ),
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
    debugPrint(
      'SHEET DATA: event.createdBy=${event.createdBy}, user.id=${user?.id}',
    );
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.subtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
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
            const SizedBox(height: 6),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 6),
            _Action(
              icon: Icons.delete_outline_rounded,
              label: 'Delete countdown',
              destructive: true,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(
                  rootNavigatorKey.currentContext ?? context,
                );
                if (user == null ||
                    (event.createdBy != user.id && !event.canManage(user.id))) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Only the owner can delete this countdown.',
                      ),
                    ),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
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
                  ref.invalidate(eventsProvider);
                  ref.read(selectedEventIdProvider.notifier).set(null);
                  onDeleted?.call();
                } on DataFailure catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Could not delete. Try again.'),
                    ),
                  );
                }
              },
            ),
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
