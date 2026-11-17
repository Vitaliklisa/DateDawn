import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../widgets/invitations_inbox.dart';

/// Everything waiting on your answer, in one place.
///
/// Countdown invitations and circle invitations arrive through different
/// documents but land in the same list, because from the user's side there is
/// only ever one question: do I want this or not?
class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invitations),
      ),
      body: user == null
          ? _SignIn(onSignIn: () => context.push(Routes.login))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              children: [
                Text(
                  l10n.waitingOnYou,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.invitationsEmptyDescription,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.5, color: colors.muted),
                ),
                const SizedBox(height: 22),
                const InvitationsInbox(showWhenEmpty: true),
              ],
            ),
    );
  }
}

class _SignIn extends StatelessWidget {
  const _SignIn({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded, size: 32, color: colors.accent),
            const SizedBox(height: 18),
            Text(
              l10n.signInToSeeInvitations,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.invitationsEmailAccount,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: colors.muted),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onSignIn, child: Text(l10n.signIn)),
          ],
        ),
      ),
    );
  }
}
