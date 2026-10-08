import 'package:datedawn/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The invitation states drive both the status chip and the accept/decline
/// guard, so they are worth pinning down: a settled invitation that still looks
/// like it needs an answer is what produced the repeated "Accept" requests.
void main() {
  group('InviteStatus', () {
    test('only pending and reopened await an answer', () {
      expect(InviteStatus.pending.isAwaitingAnswer, isTrue);
      expect(InviteStatus.reopened.isAwaitingAnswer, isTrue);

      // An answered invitation must not look like it still needs one.
      expect(InviteStatus.accepted.isAwaitingAnswer, isFalse);
      expect(InviteStatus.declined.isAwaitingAnswer, isFalse);
      expect(InviteStatus.rejected.isAwaitingAnswer, isFalse);
    });

    test('settled is the exact inverse of awaiting', () {
      for (final status in InviteStatus.values) {
        expect(status.isSettled, !status.isAwaitingAnswer, reason: '$status');
      }
    });

    test('declined and rejected stay distinct on the wire', () {
      // They mean different things to the UI: `declined` is a person who said
      // no and can be asked again, `rejected` is a row that was cancelled.
      expect(InviteStatus.fromWire('declined'), InviteStatus.declined);
      expect(InviteStatus.fromWire('rejected'), InviteStatus.rejected);
      expect(InviteStatus.fromWire('reopened'), InviteStatus.reopened);
      expect(InviteStatus.fromWire('accepted'), InviteStatus.accepted);
    });

    test('an unknown or missing wire value falls back to pending', () {
      // A status written by a newer client must not crash an older one, and
      // must not be mistaken for an answer that was actually given.
      expect(InviteStatus.fromWire('something-new'), InviteStatus.pending);
      expect(InviteStatus.fromWire(null), InviteStatus.pending);
      expect(InviteStatus.fromWire(42), InviteStatus.pending);
    });
  });
}
