import 'dart:convert';

import 'package:datedawn/services/deletion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('sends the exact account confirmation with the Firebase ID token',
      () async {
    final auth = _MockFirebaseAuth();
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response('{"success":true}', 200);
    });
    final service = DeletionService(
      auth: auth,
      client: client,
      apiBase: Uri.parse('https://date-dawn.vercel.app'),
      tokenProvider: () async => 'firebase-id-token',
    );

    await service.deleteAccount('Alex@example.com');

    expect(sentRequest.url.path, '/api/delete-account');
    expect(sentRequest.headers['authorization'], 'Bearer firebase-id-token');
    expect(
      (jsonDecode(sentRequest.body) as Map<String, dynamic>)['confirmation'],
      'Alex@example.com',
    );
    service.close();
  });

  test('surfaces an ownership rejection from the deletion API', () async {
    final service = DeletionService(
      auth: _MockFirebaseAuth(),
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"error":"Only the event owner can delete it."}',
          403,
        ),
      ),
      apiBase: Uri.parse('https://date-dawn.vercel.app'),
      tokenProvider: () async => 'firebase-id-token',
    );

    await expectLater(
      service.deleteEvent('event-id'),
      throwsA(
        isA<DeletionFailure>().having(
          (failure) => failure.message,
          'message',
          'Only the event owner can delete it.',
        ),
      ),
    );
    service.close();
  });
}
