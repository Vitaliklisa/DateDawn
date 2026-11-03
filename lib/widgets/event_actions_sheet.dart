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
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _EventActionsSheet(
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

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      ListTile(
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(event.isPast ? 'Passed' : 'Counting down'),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.open_in_new),
        title: const Text('Open'),
        onTap: () {
          Navigator.of(context).pop();
          context.push('/event/${event.id}');
        },
      ),
      if (canEdit)
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit'),
          onTap: () {
            Navigator.of(context).pop();
            context.push('/event/${event.id}/edit', extra: event);
          },
        ),
      ListTile(
        leading: const Icon(Icons.share_outlined),
        title: const Text('Share'),
        onTap: () {
          Navigator.of(context).pop();
          shareEvent(context, event);
        },
      ),
      if (user != null)
        ListTile(
          leading: const Icon(Icons.copy_outlined),
          title: const Text('Duplicate a year later'),
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
    ];

    debugPrint(
      'Delete check: event.createdBy=${event.createdBy}, user.id=${user?.id}',
    );
    if (user != null &&
        (event.createdBy == user.id || event.canManage(user.id))) {
      children.addAll([
        const Divider(),
        ListTile(
          leading: Icon(Icons.delete_outline, color: colors.danger),
          title: Text(
            'Delete countdown',
            style: TextStyle(color: colors.danger),
          ),
          onTap: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
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
      ]);
    }

    children.add(const SizedBox(height: 10));
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
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
