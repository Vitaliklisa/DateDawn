import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/models.dart';
import 'providers/app_providers.dart';
import 'screens/circles_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/event_editor_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invitations_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_navigation_shell.dart';

/// Route names, kept in one place so navigation calls never use raw strings.
class Routes {
  const Routes._();

  static const home = '/';
  static const login = '/login';
  static const settings = '/settings';
  static const newEvent = '/event/new';
  static const eventDetail = '/event';
  static const invitations = '/invitations';
  static const circles = '/circles';
  static const notifications = '/notifications';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    redirect: (context, state) {
      final auth = ref.read(activeAuthStateProvider);
      final goingToLogin = state.matchedLocation == Routes.login;

      if (auth.isLoading) {
        return goingToLogin ? null : _loginLocation(state.uri);
      }

      final user = auth.value;
      final signedIn = user != null && !user.isAnonymous;

      if (!signedIn && !goingToLogin) return _loginLocation(state.uri);
      if (signedIn && goingToLogin) {
        final destination = state.uri.queryParameters['from'];
        if (destination != null &&
            destination.startsWith('/') &&
            !destination.startsWith('//') &&
            destination != Routes.login) {
          return destination;
        }
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppNavigationShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: Routes.invitations,
            name: 'invitations',
            builder: (context, state) => const InvitationsScreen(),
          ),
          GoRoute(
            path: Routes.circles,
            name: 'circles',
            builder: (context, state) => const CirclesScreen(),
          ),
          GoRoute(
            path: Routes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: Routes.newEvent,
            name: 'newEvent',
            builder: (context, state) => EventEditorScreen(
              event: state.extra is CountdownEvent
                  ? state.extra as CountdownEvent
                  : null,
            ),
          ),
          // Keep the edit route before the detail route so `/event/:id/edit`
          // cannot be mistaken for an event whose id is `:id/edit`.
          GoRoute(
            path: '${Routes.eventDetail}/:id/edit',
            name: 'editEvent',
            builder: (context, state) => EventEditorScreen(
              event: state.extra is CountdownEvent
                  ? state.extra as CountdownEvent
                  : null,
            ),
          ),
          GoRoute(
            path: '${Routes.eventDetail}/:id',
            name: 'eventDetail',
            builder: (context, state) => EventDetailScreen(
              eventId: state.pathParameters['id']!,
              startInEditMode: state.uri.queryParameters['edit'] == '1',
            ),
          ),
        ],
      ),
    ],
  );

  ref.listen(activeAuthStateProvider, (_, __) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

String _loginLocation(Uri destination) => Uri(
      path: Routes.login,
      queryParameters: {'from': destination.toString()},
    ).toString();
