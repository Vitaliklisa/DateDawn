import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../widgets/brand_kit.dart';

/// Account and appearance. Appearance is a device preference, so it is
/// reachable signed in or out — needing an account to pick dark mode would be
/// odd.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final eventCount = ref.watch(eventsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          if (user != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    initials: user.initials,
                    photoUrl: user.photoUrl,
                    size: 46,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName?.isNotEmpty == true
                              ? user.displayName!
                              : 'Date Dawn user',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.isAnonymous ? 'Guest account' : user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$eventCount ${eventCount == 1 ? 'countdown' : 'countdowns'}',
                      style: TextStyle(fontSize: 11.5, color: colors.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are not signed in',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to sync your countdowns across every device and share '
                    'them with other people.',
                    style: TextStyle(
                        fontSize: 13, height: 1.45, color: colors.muted),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.push(Routes.login),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Text('APPEARANCE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          _ThemeSelector(
            value: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode),
          ),
          const SizedBox(height: 28),
          Text('ABOUT', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Version',
            value: '1.0.0',
          ),
          const SizedBox(height: 8),
          const _InfoRow(
            icon: Icons.cloud_outlined,
            label: 'Sync',
            value: 'Firebase',
          ),
          if (user != null) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await runAction(
                  context,
                  () => ref.read(authServiceProvider).signOut(),
                  successMessage: 'Signed out.',
                );
                if (context.mounted) context.go(Routes.home);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = <(ThemeMode, String, IconData)>[
      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
      (ThemeMode.light, 'Light', Icons.light_mode_outlined),
      (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    ];

    return Row(
      children: [
        for (final (mode, label, icon) in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: value == mode ? colors.accentSoft : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value == mode ? colors.accent : colors.border,
                    width: value == mode ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: value == mode ? colors.accent : colors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: value == mode ? colors.accent : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (mode != ThemeMode.system) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value, style: TextStyle(fontSize: 13, color: colors.subtle)),
        ],
      ),
    );
  }
}
