import 'package:datedawn/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The claim that stops an invitation being answered twice.
///
/// This lives in a provider rather than widget state precisely because widget
/// state did not survive: the inbox is mounted in more than one place, and each
/// card remounts as the Firestore streams re-emit, discarding any per-card flag
/// and letting the write fire again. These tests pin the two properties that
/// make it work — the claim is atomic, and it outlives a rebuild.
void main() {
  test('the first claim wins and the second is refused', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(invitationSubmissionProvider.notifier);

    expect(notifier.claim('event-n1'), isTrue);
    // The whole point: a second card, or a second tap, must not get through.
    expect(notifier.claim('event-n1'), isFalse);
    expect(notifier.claim('event-n1'), isFalse);
  });

  test('claims are per invitation, not global', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(invitationSubmissionProvider.notifier);

    expect(notifier.claim('event-n1'), isTrue);
    // Answering one invitation must not block the next one.
    expect(notifier.claim('event-n2'), isTrue);
    expect(notifier.claim('circle-c1'), isTrue);
  });

  test('a claim survives a reader being rebuilt', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(invitationSubmissionProvider.notifier).claim('event-n1');

    // Re-reading mimics a widget rebuild or remount: the state is still there.
    // With a `bool _submitted` on the card this was the exact moment the guard
    // was lost.
    expect(container.read(invitationSubmissionProvider), contains('event-n1'));
    expect(
      container.read(invitationSubmissionProvider.notifier).claim('event-n1'),
      isFalse,
    );
  });

  test('release allows a genuine retry after a failure', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(invitationSubmissionProvider.notifier);

    notifier.claim('event-n1');
    // A refused write changed nothing, so the invitation is still open and a
    // second attempt must be possible.
    notifier.release('event-n1');
    expect(notifier.claim('event-n1'), isTrue);
  });

  test('releasing an unclaimed key is harmless', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Must not throw: a failure path can release something it never claimed.
    container.read(invitationSubmissionProvider.notifier).release('nope');
    expect(container.read(invitationSubmissionProvider), isEmpty);
  });
}
