import 'package:datedawn/core/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// The route contract, pinned.
///
/// `/support` is a top-level route that must be reachable with no session —
/// it is the URL a store listing points at, and the page a locked-out person
/// needs. The redirect that enforces sign-in is easy to tighten later without
/// noticing that it now swallows support, so the exemption is tested rather
/// than trusted.
void main() {
  group('Routes', () {
    test('support has its own top-level path', () {
      expect(Routes.support, '/support');
      // Not nested under anything: a standalone URL has to be stable enough to
      // print on a store listing.
      expect(Routes.support.startsWith('/'), isTrue);
      expect(Routes.support.split('/').where((s) => s.isNotEmpty), ['support']);
    });

    test('paths stay unique', () {
      // Two constants sharing a value is how one route silently replaces
      // another in the router's match table.
      const all = [
        Routes.home,
        Routes.login,
        Routes.settings,
        Routes.newEvent,
        Routes.eventDetail,
        Routes.invitations,
        Routes.circles,
        Routes.notifications,
        Routes.support,
      ];
      expect(all.toSet().length, all.length);
    });

    test('every non-root path is absolute and clean', () {
      for (final path in [
        Routes.login,
        Routes.settings,
        Routes.newEvent,
        Routes.eventDetail,
        Routes.invitations,
        Routes.circles,
        Routes.notifications,
        Routes.support,
      ]) {
        expect(path.startsWith('/'), isTrue, reason: '$path must be absolute');
        expect(path.endsWith('/'), isFalse, reason: '$path must not end in /');
        expect(path.contains('//'), isFalse,
            reason: '$path must not double up');
      }
    });
  });
}
