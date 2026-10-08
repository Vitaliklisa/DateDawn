import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/models.dart';
import 'core/routes.dart';
import 'providers/app_providers.dart';
import 'screens/circles_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/event_editor_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invitations_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/support_screen.dart';
import 'widgets/app_navigation_shell.dart';

/// Route names, kept in one place so navigation calls never use raw strings.
///
/// Defined in `core/routes.dart` and re-exported here, so screens that already
/// import this file keep working while the definition stays importable by a
/// screen without creating a cycle.
export 'core/routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes reachable without a session.
///
/// Login obviously, and support: an app whose help page demands you sign in
/// first has no help page. Everything else is behind the redirect.
bool _isPublic(String location) {
  if (location == Routes.login) return true;
  return location == Routes.support ||
      location.startsWith('${Routes.support}/');
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    redirect: (context, state) {
      final auth = ref.read(activeAuthStateProvider);
      final goingToLogin = state.matchedLocation == Routes.login;

      // Support must stay reachable when signed out. Somebody who cannot get
      // into their account — or a store reviewer checking that the support URL
      // in the listing resolves — has to be able to reach us without a working
      // session.
      //
      // Matched as a prefix, not with `==`, so `/support` and any path under it
      // (a trailing slash, a future `/support/faq`, a deep link) all stay public.
      // An exact match here would silently send `/support/` to the login screen,
      // which is exactly the dead end this exemption exists to prevent.
      if (_isPublic(state.matchedLocation)) return null;

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
      // Support is a top-level route, deliberately OUTSIDE the ShellRoute.
      //
      // Inside it, the page inherited the sidebar and the mobile tab bar —
      // chrome that implies "you are somewhere in the app" for a page that is
      // meant to be findable by someone who cannot get into the app at all. As
      // a standalone route it renders its own AppBar with a real back button,
      // and it is reachable at a stable URL a store listing can point at.
      GoRoute(
        path: Routes.support,
        name: 'support',
        builder: (context, state) => const SupportScreen(),
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
