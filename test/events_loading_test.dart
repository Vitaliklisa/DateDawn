import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';

void main() {
  test('events stay loading until the auth session is restored', () {
    // A stream that has not emitted yet models Firebase still restoring the
    // persisted session after a refresh.
    final never = StreamController<AppUser?>();
    addTearDown(never.close);

    final container = ProviderContainer(
      overrides: [
        activeAuthStateProvider.overrideWith((ref) => never.stream),
      ],
    );
    addTearDown(container.dispose);

    // A refresh must not look like an empty account: the events feed has to
    // remain unresolved (loading) rather than emitting `[]`, which is what
    // used to blank the home screen and make countdowns look unsaved.
    final events = container.read(eventsProvider);
    expect(events.isLoading, isTrue);
    expect(events.value, isNull);
    expect(container.read(authResolvedProvider), isFalse);
  });
}
