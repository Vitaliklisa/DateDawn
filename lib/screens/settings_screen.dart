import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/time_format.dart';
import '../l10n/app_localizations_context.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import '../widgets/brand_kit.dart';
import '../widgets/language_selector.dart';

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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
                          user.displayName?.trim().isNotEmpty == true
                              ? user.displayName!.trim()
                              : l10n.dateDawnUser,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.isAnonymous ? l10n.guestAccount : user.email,
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
                      l10n.countdownsCount(eventCount),
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
                  Text(
                    l10n.notSignedIn,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.syncAndShareDescription,
                    style: TextStyle(
                        fontSize: 13, height: 1.45, color: colors.muted),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.push(Routes.login),
                    child: Text(l10n.signIn),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Text(l10n.language.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          const LanguageSelector(),
          const SizedBox(height: 28),
          Text(l10n.appearance, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          _ThemeSelector(
            value: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode),
          ),
          const SizedBox(height: 28),
          Text(l10n.time, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            l10n.timeFormatDescription,
            style: TextStyle(fontSize: 13, height: 1.45, color: colors.muted),
          ),
          const SizedBox(height: 12),
          _TimeFormatSelector(
            value: timeFormat,
            onChanged: (format) =>
                ref.read(timeFormatProvider.notifier).set(format),
          ),
          const SizedBox(height: 28),
          Text(l10n.about, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: l10n.version,
            value: '1.0.0',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.cloud_outlined,
            label: l10n.sync,
            value: 'Firebase',
          ),
          const SizedBox(height: 28),
          // Blocking is required by Google Play's UGC policy, and a block is
          // only honest if the person can see it and undo it.
          Text(l10n.safety, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          _SettingsLink(
            icon: Icons.block_outlined,
            label: l10n.blockedPeople,
            onTap: () => context.go(Routes.blocked),
          ),
          const SizedBox(height: 28),
          Text(l10n.legal, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          _SettingsLink(
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacyPolicy,
            onTap: () => openLegalPage(context, LegalDocument.privacy),
          ),
          const SizedBox(height: 8),
          _SettingsLink(
            icon: Icons.description_outlined,
            label: l10n.termsOfService,
            onTap: () => openLegalPage(context, LegalDocument.terms),
          ),
          const SizedBox(height: 20),
          // Support is linked from Settings, which is the first place someone
          // looks, and it is also reachable signed out so a locked-out account
          // can still ask for help.
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.support),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: Text(l10n.helpAndSupport),
          ),
          if (user != null) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await runAction(
                  context,
                  () => ref.read(authServiceProvider).signOut(),
                  successMessage: l10n.signedOut,
                );
                if (context.mounted) context.go(Routes.home);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.signOut),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.danger.withValues(alpha: 0.6)),
              ),
              onPressed: () => context.go(Routes.deleteAccount),
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: Text(l10n.deleteAccount),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.muted),
        title: Text(label),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 15, color: colors.subtle),
        onTap: onTap,
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
    final l10n = context.l10n;
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
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        const TimeOfDay(hour: 15, minute: 40),
                        alwaysUse24HourFormat: option.uses24HourClock,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: value == option ? colors.accent : colors.fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option == TimeFormat.twelveHour
                          ? l10n.twelveHourTime
                          : l10n.twentyFourHourTime,
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
    final l10n = context.l10n;
    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.dark, l10n.darkTheme, Icons.dark_mode_outlined),
      (ThemeMode.light, l10n.lightTheme, Icons.light_mode_outlined),
      (ThemeMode.system, l10n.systemTheme, Icons.brightness_auto_outlined),
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
