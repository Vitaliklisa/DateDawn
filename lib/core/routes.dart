import 'package:flutter/widgets.dart';
// Riverpod 3 moved `StateProvider` out of the main entrypoint.
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route paths, in their own file so screens can refer to a route without
/// importing `router.dart`.
///
/// `router.dart` imports every screen, so a screen importing it back is a cycle
/// — and Dart will happily compile one until something is read before it is
/// initialised, which is a confusing runtime failure rather than a build error.
/// Keeping the constants here breaks the cycle: this file imports no screen and
/// no router.
///
/// Re-exported from `router.dart` as `Routes`, so existing imports of
/// `../router.dart` keep working and there is still only one definition.
/// The support address printed in both store listings and on every page that
/// talks to a person about their account.
///
/// One constant on purpose: it is quoted in the policy text, the support
/// screen, the FAQ answers and the store forms, and when it only lived in
/// `support_screen.dart` the policy copy silently kept the old address.
const supportEmailAddress = 'datedawnsupport@gmail.com';

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

  /// People this account has blocked. Behind the sign-in gate like every other
  /// personal page — there is nothing to show to a signed-out visitor.
  static const blocked = '/blocked';

  /// Help & support. Public — reachable with no session, on purpose.
  static const support = '/support';

  /// The legal pages. Public, like support.
  ///
  /// **Reached with `openLegalPage`, never `context.push`.** GoRouter's
  /// `push` is a no-op inside a `ShellRoute` whose page is keyed by its first
  /// match (which this app's is, so the sidebar survives navigating between
  /// sections): the new page is kept as a secondary, never becomes current,
  /// and the URL never moves — the tap looks dead. `go` replaced the whole
  /// stack, which worked but broke Back. StatefulShellRoute is not an option
  /// either, since it keeps every destination mounted at once.
  ///
  /// So the policy is shown as a page *on top*, inside the app's own
  /// navigator, driven by [legalDocumentProvider] — see `openLegalPage`.
  static const privacy = '/privacy';
  static const terms = '/terms';
}

/// Which legal document, if any, is open over the current page.
///
/// `null` means closed. Read by `AppNavigationShell`, which renders the page as
/// a full-screen layer above the shell's content — so it covers the sidebar and
/// the bottom bar, the way a policy page should.
final legalDocumentProvider = StateProvider<LegalDocument?>((ref) => null);

enum LegalDocument {
  privacy(Routes.privacy, 'Privacy Policy'),
  terms(Routes.terms, 'Terms of Service');

  const LegalDocument(this.path, this.title);
  final String path;
  final String title;
}

/// Where closing a legal page should go back to — the page it was opened from.
///
/// Remembered because the URL moves to the document's own path (so it can be
/// shared, and a reload lands in the same place), which would otherwise lose
/// the fact that it was Support rather than Settings that opened it.
final _legalReturnPath = <LegalDocument, String>{};

/// Opens a legal page from Settings or Support.
///
/// The document is shown as a layer over the shell (see
/// [legalDocumentProvider]), and the URL is updated with `go` alongside it. `go`
/// rather than `push` is deliberate: `push` of a sibling route inside a
/// `ShellRoute` silently does nothing — see [Routes.privacy]. Because `go`
/// replaces the stack rather than pushing onto it, [closeLegalPage] carries the
/// Back destination itself.
void openLegalPage(BuildContext context, LegalDocument document) {
  final container = ProviderScope.containerOf(context, listen: false);
  final current = GoRouterState.of(context).uri.path;
  if (current != document.path) {
    _legalReturnPath[document] = current;
  }
  container.read(legalDocumentProvider.notifier).state = document;
  GoRouter.of(context).go(document.path);
}

/// Closes the open legal page and returns to the page that opened it.
void closeLegalPage(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final open = container.read(legalDocumentProvider);
  final back = open == null ? null : _legalReturnPath[open];
  container.read(legalDocumentProvider.notifier).state = null;
  GoRouter.of(context).go(back ?? Routes.support);
}

/// The document a path names, if any — used to open one on a cold load.
LegalDocument? legalDocumentAt(String path) {
  for (final document in LegalDocument.values) {
    if (document.path == path) return document;
  }
  return null;
}
