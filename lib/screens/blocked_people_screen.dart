import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../widgets/brand_kit.dart';

/// Everyone this account has blocked, with the undo right there.
///
/// Required by Google Play's user-generated-content policy. The policy asks for
/// blocking *in-app*; a block with no visible list and no way back would still
/// fail the spirit of it, and a person who blocked someone by accident would
/// have no route out.
class BlockedPeopleScreen extends ConsumerWidget {
  const BlockedPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final router = GoRouter.of(context);
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked people'),
        leading: router.canPop()
            ? HoverTintIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () =>
                    router.canPop() ? router.pop() : router.go(Routes.settings),
              )
            : null,
      ),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your blocked list. ${error is String ? error : ''}'
                .trim(),
            style: TextStyle(fontSize: 13.5, color: colors.muted),
          ),
        ),
        data: (people) {
          if (people.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nobody is blocked',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To block someone, open a countdown you share with them and '
                    'long-press their name in the people list.',
                    style: TextStyle(
                        fontSize: 13.5, height: 1.5, color: colors.muted),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text(
                'These people cannot invite you, and you do not share any '
                'countdown with them. They are not told they are blocked.',
                style:
                    TextStyle(fontSize: 13, height: 1.5, color: colors.muted),
              ),
              const SizedBox(height: 18),
              for (final person in people) ...[
                _BlockedRow(
                  person: person,
                  onUnblock: () => _unblock(context, ref, person),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser person,
  ) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    await runAction(
      context,
      () => ref
          .read(eventRepositoryProvider)
          .unblockUser(userId: me.id, targetUid: person.userId),
      successMessage: '${person.label} is unblocked.',
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.person, required this.onUnblock});

  final BlockedUser person;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          UserAvatar(
            initials: _initials(person),
            seed: person.userId,
            photoUrl: person.photoUrl,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                if (person.email.isNotEmpty && person.displayName != null)
                  Text(
                    person.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.subtle),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  static String _initials(BlockedUser person) {
    final name = (person.displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      return parts.take(2).map((p) => p[0].toUpperCase()).join();
    }
    final email = person.email;
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}
