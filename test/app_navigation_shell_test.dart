import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/widgets/app_navigation_shell.dart';

void main() {
  testWidgets('desktop navigation changes to dedicated section routes',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppNavigationShell(
            location: state.uri.path,
            child: child,
          ),
          routes: [
            for (final path in [
              '/',
              '/invitations',
              '/circles',
              '/notifications',
              '/settings',
            ])
              GoRoute(
                path: path,
                builder: (context, state) => Scaffold(
                  body: Center(child: Text('$path page')),
                ),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) => null)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('/settings page'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    for (final (label, path) in [
      ('Invitations', '/invitations'),
      ('Circles', '/circles'),
      ('Notifications', '/notifications'),
      ('Settings', '/settings'),
      ('Home', '/'),
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.text('$path page'), findsOneWidget);
    }
  });

  testWidgets('mobile navigation stays available at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) => null)],
        child: const MaterialApp(
          home: AppNavigationShell(
            location: '/invitations',
            child: Scaffold(body: Text('Invitations page')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invitations page'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
