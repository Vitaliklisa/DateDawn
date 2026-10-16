import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:datedawn/widgets/invitations_inbox.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService(Stream<AppUser?> authState)
      : _authState = authState,
        super(auth: _FakeFirebaseAuth());

  final Stream<AppUser?> _authState;

  @override
  Stream<AppUser?> authStateChanges() => _authState;
}

void main() {
  testWidgets('automatically joins a pending couple-circle invitation',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    final expiresAt = DateTime.now().add(const Duration(days: 1));
    await firestore.collection('circles').doc('circle-1').set({
      'name': 'Us',
      'ownerId': 'alex',
      'isCouple': true,
      'createdAt': Timestamp.now(),
      'memberIds': ['alex'],
    });
    await firestore.collection('circle_invitations').doc('invite-1').set({
      'circleId': 'circle-1',
      'invitedBy': 'alex',
      'invitedByName': 'Alex',
      'inviteeEmail': 'sam@example.com',
      'circleName': 'Us',
      'isCouple': true,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(
            _TestAuthService(
              Stream.value(
                const AppUser(
                  id: 'sam',
                  email: 'sam@example.com',
                  displayName: 'Sam',
                ),
              ),
            ),
          ),
          eventRepositoryProvider.overrideWithValue(
            EventRepository(firestore: firestore),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InvitationsInbox(showWhenEmpty: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final circle =
        (await firestore.collection('circles').doc('circle-1').get()).data()!;
    final invitation =
        (await firestore.collection('circle_invitations').doc('invite-1').get())
            .data()!;
    expect(circle['memberIds'], contains('sam'));
    expect(invitation['status'], 'accepted');
    expect(find.text('Nothing waiting'), findsOneWidget);
  });
}
