import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../router.dart';
import 'brand_kit.dart';

class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const _destinations = <(String, String, IconData)>[
    ('Home', Routes.home, Icons.hourglass_bottom_rounded),
    ('Invitations', Routes.invitations, Icons.mail_outline_rounded),
    ('Circles', Routes.circles, Icons.groups_outlined),
    ('Notifications', Routes.notifications, Icons.notifications_none_rounded),
    ('Settings', Routes.settings, Icons.settings_outlined),
  ];

  int get _selectedIndex {
    for (var i = 1; i < _destinations.length; i++) {
      if (location == _destinations[i].$2 ||
          location.startsWith('${_destinations[i].$2}/')) {
        return i;
      }
    }
    return 0;
  }

  void _goTo(BuildContext context, int index) {
    final destination = _destinations[index].$2;
    if (location != destination) context.go(destination);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (!desktop) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _goTo(context, index),
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.$3),
                    label: destination.$1,
                  ),
              ],
            ),
          );
        }

        final colors = context.colors;
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 248,
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(right: BorderSide(color: colors.border)),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 20, 28),
                        child: BrandMark(),
                      ),
                      for (var i = 0; i < _destinations.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          child: _SidebarDestination(
                            label: _destinations[i].$1,
                            icon: _destinations[i].$3,
                            selected: _selectedIndex == i,
                            onTap: () => _goTo(context, i),
                          ),
                        ),
                      const Spacer(),
                      if (user != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                          child: Row(
                            children: [
                              UserAvatar(
                                initials: user.initials,
                                photoUrl: user.photoUrl,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  user.displayName?.trim().isNotEmpty == true
                                      ? user.displayName!
                                      : user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          size: 20,
          color: selected ? colors.accent : colors.muted,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.accent : colors.muted,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
