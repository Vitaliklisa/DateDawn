import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../services/event_repository.dart';
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
    final refreshing = blocked.isLoading && blocked.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked people'),
        bottom: refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
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
        // A refresh of a list that is already on screen keeps the list visible
        // and shows progress where it belongs — in the bar — rather than
        // replacing real content with a spinner.
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BlockedListError(
          error: error,
          onRetry: () async => ref.read(blockedUsersProvider.notifier).retry(),
        ),
        data: (people) {
          if (people.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined,
                      size: 24, color: colors.accent),
                ),
                const SizedBox(height: 20),
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
                  'To block someone, open a countdown you share with them, open '
                  'the ⋮ menu on their row, and tap Block.',
                  style: TextStyle(
                      fontSize: 13.5, height: 1.5, color: colors.muted),
                ),
              ],
            );
          }
          // Live, but not infinite: this is a snapshot stream, so a block or
          // unblock made elsewhere arrives on its own. Pull to refresh re-reads
          // it anyway, which is what makes a stuck-looking list recoverable.
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(blockedUsersProvider.notifier).retry(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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
    // The list is a live snapshot, but an unblock also needs the invitations
    // inbox to re-admit anything the block was filtering out.
    ref.invalidate(blockedUsersProvider);
    ref.invalidate(invitationsProvider);
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

/// The list could not be read — said plainly, with the reason and a way back.
///
/// This screen used to show a spinner that never finished. Turning that into
/// an error is only half the fix: without Retry, a Firestore hiccup that would
/// have cleared itself leaves the user with no option but to restart the app.
class _BlockedListError extends StatelessWidget {
  const _BlockedListError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = switch (error) {
      DataFailure(:final message) => message,
      FirebaseException(code: 'permission-denied') =>
        'Your account is not allowed to read this list. If this keeps '
            'happening, update the app.',
      FirebaseException(code: 'unavailable') ||
      FirebaseException(code: 'network-request-failed') =>
        'No connection. Check your network and try again.',
      _ => 'Check your connection and try again.',
    };

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Icon(Icons.cloud_off_rounded,
                          size: 22, color: colors.danger),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Could not load your blocked list',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.5, color: colors.muted),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => onRetry(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
