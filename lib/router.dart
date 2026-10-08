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
            routes: [
              // `/home/:id` pins one countdown as the hero.
              //
              // **The `home/` prefix is required, not cosmetic.** `Routes.home`
              // is `/`, so a bare `:id` child makes the home route match
              // `/anything` — GoRouter matches `/` then lets `:id` swallow the
              // next segment. That silently captured `/support` and rendered the
              // home screen at the support URL, while the sidebar (which reads
              // the URL string, not the matched route) highlighted Support. Two
              // sources of truth disagreeing: the highlight said Support, the
              // body said Home.
              //
              // An explicit `home/:id` segment cannot collide with a sibling
              // top-level route, because `/support` no longer matches `/` +
              // `:id`.
              //
              // Additive on purpose: `/` still works and still picks the
              // countdown automatically, so existing links do not break.
              GoRoute(
                path: 'home/:id',
                name: 'homeEvent',
                builder: (context, state) => HomeScreen(
                  focusedEventId: state.pathParameters['id'],
                ),
              ),
            ],
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
          // Support sits inside the shell like every other page, so it gets the
          // same navigation: the sidebar on desktop, and a route the bottom bar
          // and Settings can both reach. Earlier it was a standalone top-level
          // route, which made it the one page in the app with different chrome.
          //
          // The public exemption in the redirect is what keeps it reachable
          // signed out — position in this tree has nothing to do with access.
          GoRoute(
            path: Routes.support,
            name: 'support',
            builder: (context, state) => const SupportScreen(),
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
