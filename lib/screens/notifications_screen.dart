import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';

/// Answers to invitations you sent — the feedback half of inviting someone.
///
/// When a friend accepts or declines, one line lands here naming the countdown
/// and what they chose. It is a log rather than a popup so an answer that
/// arrives while you are offline is still waiting when you come back.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final responses = ref.watch(responsesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if ((responses.value ?? const []).any((r) => !r.read))
            TextButton(
              onPressed: () async {
                final unread = (responses.value ?? const [])
                    .where((r) => !r.read)
                    .toList();
                for (final response in unread) {
                  await ref
                      .read(eventRepositoryProvider)
                      .markResponseRead(response.id);
                }
              },
              child:
                  const Text('Mark all read', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: user == null
          ? const _Empty(
              icon: Icons.notifications_none_rounded,
              title: 'Sign in first',
              body: 'Notifications are tied to your account.',
            )
          : responses.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const _Empty(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load',
                body: 'Check your connection and try again.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _Empty(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nothing yet',
                    body:
                        'When someone accepts or declines an invitation you sent, '
                        'it will show up here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final response = items[index];
                    return _ResponseTile(
                      key: ValueKey(response.id),
                      message: response.message,
                      accepted: response.accepted,
                      unread: !response.read,
                      onTap: () {
                        if (!response.read) {
                          ref
                              .read(eventRepositoryProvider)
                              .markResponseRead(response.id);
                        }
                        if (response.eventId.isNotEmpty) {
                          context.push('/event/${response.eventId}');
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({
    super.key,
    required this.message,
    required this.accepted,
    required this.unread,
    required this.onTap,
  });

  final String message;
  final bool accepted;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread
                  ? colors.accent.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accepted ? colors.accentSoft : colors.surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  accepted ? Icons.check_rounded : Icons.close_rounded,
                  size: 18,
                  color: accepted ? colors.accent : colors.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
              if (unread)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.subtle),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: colors.fg),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
