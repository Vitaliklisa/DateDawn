import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DeletionFailure implements Exception {
  const DeletionFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Calls the authenticated Vercel Admin SDK endpoints. No Admin credentials
/// or Firestore elevated privileges are present in the Flutter client.
class DeletionService {
  DeletionService({
    FirebaseAuth? auth,
    http.Client? client,
    Uri? apiBase,
    Duration requestTimeout = const Duration(seconds: 30),
    Duration accountDeletionTimeout = const Duration(seconds: 120),
    Future<String?> Function()? tokenProvider,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client(),
        _apiBase = apiBase ??
            (kIsWeb ? Uri.base : Uri.parse('https://date-dawn.vercel.app')),
        _requestTimeout = requestTimeout,
        _accountDeletionTimeout = accountDeletionTimeout,
        _tokenProvider = tokenProvider;

  final FirebaseAuth _auth;
  final http.Client _client;
  final Uri _apiBase;
  final Duration _requestTimeout;
  final Duration _accountDeletionTimeout;
  final Future<String?> Function()? _tokenProvider;

  Future<void> deleteAccount(String confirmation) => _post(
        'api/delete-account',
        {'confirmation': confirmation},
        responseTimeout: _accountDeletionTimeout,
      );

  Future<void> deleteEvent(String eventId) =>
      _post('api/delete-event', {'eventId': eventId});

  Future<void> deleteCircle(String circleId) =>
      _post('api/delete-circle', {'circleId': circleId});

  void close() => _client.close();

  Future<void> _post(
    String path,
    Map<String, String> body, {
    Duration? responseTimeout,
  }) async {
    late final String? token;
    try {
      token = await (_tokenProvider?.call() ??
              _auth.currentUser?.getIdToken() ??
              Future<String?>.value(null))
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const DeletionFailure(
        'The deletion request timed out. Please try again.',
        statusCode: 504,
      );
    }
    if (token == null || token.isEmpty) {
      throw const DeletionFailure('Sign in again before deleting data.');
    }

    late final http.Response response;
    try {
      response = await _client
          .post(
            _apiBase.resolve('/$path'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(responseTimeout ?? _requestTimeout);
    } on TimeoutException {
      throw const DeletionFailure(
        'The deletion request timed out. Please try again.',
        statusCode: 504,
      );
    } on http.ClientException {
      throw const DeletionFailure(
        'Could not connect to the deletion service. Check your connection and retry.',
      );
    }

    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // The status code below still reports an unsuccessful response.
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['success'] != true) {
      final message = payload['error'];
      throw DeletionFailure(
        message is String
            ? message
            : 'Deletion could not be completed. Please retry.',
        statusCode: response.statusCode,
      );
    }
  }
}
