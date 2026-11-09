import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncUserProfile writes the Firebase display name to the user doc',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);

    await repository.syncUserProfile(
      const AppUser(
        id: 'user-id',
        email: 'alex@example.com',
        displayName: 'Alex Rivera',
      ),
    );

    final profile = await firestore.collection('users').doc('user-id').get();
    expect(profile.data()?['email'], 'alex@example.com');
    expect(profile.data()?['displayName'], 'Alex Rivera');
  });
}
