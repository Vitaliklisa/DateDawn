import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/circles.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../widgets/brand_kit.dart';

/// Circles: the people you count down with, grouped once and reused.
///
/// The value of a circle over re-inviting by email every time is the recurring
/// case — an annual trip, a partner, a close friend group. Create it once,
/// invite the people once, then share any future countdown with one tap.
class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final circles = ref.watch(circlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circles'),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentFg,
              onPressed: () => _openCreateSheet(context, ref),
              icon: const Icon(Icons.group_add_outlined, size: 20),
              label: const Text('New circle'),
            ),
      body: user == null
          ? _SignInPrompt(onSignIn: () => context.push(Routes.login))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
              children: [
                Text(
                  'Groups you count down with',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Invite someone to a circle once, then share any countdown with '
                  'the whole group in a single tap. A couple circle shares '
                  'automatically — anything one of you creates, the other sees.',
                  style: TextStyle(
                      fontSize: 13.5, height: 1.5, color: colors.muted),
                ),
                const SizedBox(height: 24),
                circles.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Could not load your circles. Pull down to retry.',
                    style: TextStyle(fontSize: 13, color: colors.danger),
                  ),
                  data: (items) {
                    if (items.isEmpty) return const _NoCircles();
                    return Column(
                      children: [
                        for (final circle in items) ...[
                          _CircleCard(circle: circle),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _NoCircles extends StatelessWidget {
  const _NoCircles();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.groups_outlined, size: 26, color: colors.accent),
        ),
        const SizedBox(height: 20),
        Text(
          'No circles yet',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: colors.fg),
        ),
        const SizedBox(height: 8),
        Text(
          'Create one for the people you count down with — a partner, family, or '
          'the friends you take a trip with every year.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
        ),
      ],
    );
  }
}

class _CircleCard extends ConsumerWidget {
  const _CircleCard({required this.circle});

  final Circle circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final members = ref.watch(circleMembersProvider(circle.id)).value ??
        const <CircleMember>[];
    final isOwner = circle.isOwner(user?.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: circle.isCouple
              ? colors.accent.withValues(alpha: 0.35)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                circle.emoji ?? (circle.isCouple ? '💞' : '👥'),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circle.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      circle.isCouple
                          ? 'Shares automatically'
                          : '${members.length} ${members.length == 1 ? 'person' : 'people'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: circle.isCouple ? colors.accent : colors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                HoverTintIconButton(
                  tooltip: 'Invite someone',
                  iconSize: 19,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => _openInviteSheet(context, ref, circle),
                ),
            ],
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final member in members)
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(
                          initials: member.initials,
                          seed: member.userId,
                          photoUrl: member.photoUrl,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.userId == user?.id ? 'You' : member.label,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        if (member.isOwner) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              size: 13, color: colors.accent),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // A member can leave; an owner can delete. The owner had neither —
          // there was no way to remove a circle they created, which is why the
          // screen looked like it simply could not delete anything.
          if (!isOwner)
            TextButton.icon(
              onPressed: () async {
                // Capture the id before the await: reading `user` afterwards
                // would be unsafe once this widget can be disposed mid-flight.
                final userId = user?.id;
                if (userId == null) return;
                await runAction(
                  context,
                  () => ref
                      .read(eventRepositoryProvider)
                      .leaveCircle(circleId: circle.id, userId: userId),
                  successMessage: 'You left “${circle.name}”.',
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Leave circle', style: TextStyle(fontSize: 13)),
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.danger,
                overlayColor: colors.danger.withValues(alpha: 0.10),
              ),
              onPressed: () async {
                final userId = user?.id;
                if (userId == null) return;
                final confirmed = await _confirmDeleteCircle(context, circle.name);
                if (!confirmed) return;
                if (!context.mounted) return;
                await runAction(
                  context,
                  () => ref.read(eventRepositoryProvider).deleteCircle(
                        circleId: circle.id,
                        userId: userId,
                      ),
                  successMessage: 'Deleted “${circle.name}”.',
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete circle', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Confirms removing a circle, spelling out that the countdowns survive.
Future<bool> _confirmDeleteCircle(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete “$name”?'),
      content: const Text(
        'The group goes away. Countdowns shared with it are kept and stay yours — '
        'they are just no longer shared with these people.',
      ),
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

/// Create a circle, optionally as a couple circle.
Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final nameController = TextEditingController();
  var isCouple = false;
  var busy = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final colors = sheetContext.colors;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New circle',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'Family, Tokyo 2027, Us'),
              ),
              const SizedBox(height: 14),
              // The couple toggle is the whole point of the circle feature for
              // two people, so it is offered up front rather than buried.
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setSheetState(() => isCouple = !isCouple),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCouple ? colors.accentSoft : colors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCouple ? colors.accent : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💞', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This is us — a couple',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Countdowns are shared with your partner automatically, '
                              'with no invitation to accept.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isCouple,
                        onChanged: (value) =>
                            setSheetState(() => isCouple = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        setSheetState(() => busy = true);
                        await runAction(
                          sheetContext,
                          () => ref.read(eventRepositoryProvider).createCircle(
                                ownerId: user.id,
                                ownerEmail: user.email,
                                name: name,
                                ownerName: user.displayName,
                                ownerPhotoUrl: user.photoUrl,
                                emoji: isCouple ? '💞' : null,
                                isCouple: isCouple,
                              ),
                          successMessage: isCouple
                              ? 'Created. Invite your partner next.'
                              : 'Circle created.',
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    ),
  );

  nameController.dispose();
}

/// Invite someone into a circle by email.
Future<void> _openInviteSheet(
    BuildContext context, WidgetRef ref, Circle circle) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final emailController = TextEditingController();
  var busy = false;
  String? inviteError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final colors = sheetContext.colors;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                circle.isCouple
                    ? 'Invite your partner'
                    : 'Invite to “${circle.name}”',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                circle.isCouple
                    ? 'They will get an invitation to accept. Once they do, your '
                        'countdowns share with each other automatically.'
                    : 'They will get an invitation to accept or decline. After they '
                        'join, you can share countdowns with this circle in one tap.',
                style:
                    TextStyle(fontSize: 13, height: 1.5, color: colors.muted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'them@example.com'),
                onChanged: (_) {
                  if (inviteError != null) {
                    setSheetState(() => inviteError = null);
                  }
                },
              ),
              if (inviteError != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: colors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inviteError!,
                        style: TextStyle(fontSize: 13, color: colors.danger),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty) return;
                        setSheetState(() {
                          busy = true;
                          inviteError = null;
                        });
                        final failure = await runAction(
                          sheetContext,
                          () =>
                              ref.read(eventRepositoryProvider).inviteToCircle(
                                    circle: circle,
                                    inviterId: user.id,
                                    inviterEmail: user.email,
                                    email: email,
                                    inviterName: user.displayName,
                                  ),
                          successMessage: 'Invitation sent to $email.',
                        );
                        if (failure != null) {
                          if (sheetContext.mounted) {
                            setSheetState(() {
                              busy = false;
                              inviteError = failure;
                            });
                          }
                          return;
                        }
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                child: const Text('Send invitation'),
              ),
            ],
          ),
        );
      },
    ),
  );

  emailController.dispose();
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 32, color: colors.accent),
            const SizedBox(height: 18),
            Text(
              'Sign in to use circles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Circles invite people by email, so they need an account to be '
              'invited to.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onSignIn, child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}
