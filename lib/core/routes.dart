/// Route paths, in their own file so screens can refer to a route without
/// importing `router.dart`.
///
/// `router.dart` imports every screen, so a screen importing it back is a cycle
/// — and Dart will happily compile one until something is read before it is
/// initialised, which is a confusing runtime failure rather than a build error.
/// Keeping the constants here breaks the cycle: this file imports nothing.
///
/// Re-exported from `router.dart` as `Routes`, so existing imports of
/// `../router.dart` keep working and there is still only one definition.
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

  /// Help & support. Public — reachable with no session, on purpose.
  static const support = '/support';
}
