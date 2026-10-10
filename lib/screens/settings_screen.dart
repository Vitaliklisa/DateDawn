import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/time_format.dart';
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
    final timeFormat = ref.watch(timeFormatProvider);
    final themeMode = ref.watch(themeModeProvider);
    final eventCount = ref.watch(eventsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
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
                    seed: user.id,
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
          Text('TIME', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            'How clock times are written. Your countdowns are stored as exact '
            'moments either way — this only changes how they read.',
            style: TextStyle(fontSize: 13, height: 1.45, color: colors.muted),
          ),
          const SizedBox(height: 12),
          _TimeFormatSelector(
            value: timeFormat,
            onChanged: (format) =>
                ref.read(timeFormatProvider.notifier).set(format),
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
          const SizedBox(height: 20),
          // Support is linked from Settings, which is the first place someone
          // looks, and it is also reachable signed out so a locked-out account
          // can still ask for help.
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.support),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text('Help & support'),
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

/// Two side-by-side choices, each showing a live worked example of the format.
///
/// The example is the point: "12-hour (AM/PM)" is jargon, `3:40 PM` is not, and
/// seeing both next to each other is what makes the choice obvious.
class _TimeFormatSelector extends StatelessWidget {
  const _TimeFormatSelector({required this.value, required this.onChanged});

  final TimeFormat value;
  final ValueChanged<TimeFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Two entries in a fixed order; a plain list keeps the "last one" check
    // below honest, which a map's iteration order would not.
    const options = <TimeFormat>[
      TimeFormat.twelveHour,
      TimeFormat.twentyFourHour,
    ];

    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: value == option ? colors.accentSoft : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value == option ? colors.accent : colors.border,
                    width: value == option ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // The sample is formatted the real way, not a hand-typed
                    // string, so it can never drift from what the app shows.
                    Text(
                      option.example,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: value == option ? colors.accent : colors.fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: value == option ? colors.accent : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (option != options.last) const SizedBox(width: 10),
        ],
      ],
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
