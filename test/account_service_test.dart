import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_quiz_app/account_service.dart';
import 'package:flutter_quiz_app/backend_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'login calls the configured account endpoint and parses session',
    () async {
      late http.Request request;
      final service = AccountService(
        baseUrl: 'https://quiz.example/',
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'token': 'signed-token',
              'user': {
                'id': 'account-1',
                'email': 'learner@example.com',
                'displayName': 'Learner',
                'createdAt': '2026-11-28T10:00:00.000Z',
              },
            }),
            200,
          );
        }),
      );

      final session = await service.login(
        email: 'learner@example.com',
        password: 'password-123',
      );

      expect(request.url.toString(), 'https://quiz.example/api/auth/login');
      expect(jsonDecode(request.body), {
        'email': 'learner@example.com',
        'password': 'password-123',
      });
      expect(session.token, 'signed-token');
      expect(session.id, 'account-1');
      expect(session.email, 'learner@example.com');
    },
  );

  test(
    'existing auth flow uses backend session and revokes it at sign-out',
    () async {
      SharedPreferences.setMockInitialValues({});
      var logoutCalls = 0;
      final api = AccountService(
        baseUrl: 'https://quiz.example',
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'token': 'session-token',
                'user': {
                  'id': 'account-1',
                  'email': 'learner@example.com',
                  'displayName': 'Learner',
                  'createdAt': '2026-11-28T10:00:00.000Z',
                },
              }),
              200,
            );
          }
          if (request.url.path == '/api/auth/logout') {
            logoutCalls++;
            return http.Response('', 204);
          }
          return http.Response('{}', 404);
        }),
      );
      final auth = BackendAuthService(api);

      final user = await auth.signIn(
        email: 'learner@example.com',
        password: 'password-123',
      );
      expect(user.email, 'learner@example.com');
      expect((await api.loadSession())?.token, 'session-token');

      await auth.signOut();
      expect(logoutCalls, 1);
      expect(await api.loadSession(), isNull);
    },
  );

  test(
    'history request includes bearer token and decodes quiz attempt',
    () async {
      late http.Request request;
      final service = AccountService(
        baseUrl: 'https://quiz.example',
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'attempts': [
                {
                  'id': 'attempt_1',
                  'timestamp': '2026-11-28T10:00:00.000Z',
                  'isExam': false,
                  'topic': 1,
                  'totalQuestions': 1,
                  'correct': 1,
                  'wrong': 0,
                  'skipped': 0,
                  'durationSeconds': 12,
                  'expired': false,
                  'answers': {'1': 'C'},
                  'questionIds': [1],
                },
              ],
            }),
            200,
          );
        }),
      );
      const session = AccountSession(
        token: 'signed-token',
        id: 'account-1',
        email: 'learner@example.com',
        displayName: 'Learner',
      );

      final attempts = await service.loadAttempts(session);

      expect(request.url.path, '/api/history');
      expect(request.headers['authorization'], 'Bearer signed-token');
      expect(attempts.single.id, 'attempt_1');
      expect(attempts.single.answers, {1: 'C'});
    },
  );
}
