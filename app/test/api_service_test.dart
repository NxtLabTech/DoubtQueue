import 'dart:convert';

import 'package:doubtqueue/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const baseUrl = 'http://test.local';

  test('getSessions returns sessions from the API', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions?status=OPEN');
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'title': 'PHP Basics Doubt Session',
            'mentor_name': 'Priya',
            'status': 'OPEN',
            'waiting_count': 5,
          },
        ]),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final sessions = await api.getSessions(status: 'OPEN');

    expect(sessions, hasLength(1));
    expect(sessions.first.title, 'PHP Basics Doubt Session');
    expect(sessions.first.waitingCount, 5);
  });

  test('a network failure throws a friendly message', () async {
    final client = MockClient((request) async {
      throw http.ClientException('connection refused');
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(
      api.getSessions(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Could not reach the server'),
        ),
      ),
    );
  });

  test('getSessions without a status asks for every session', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions');
      return http.Response('[]', 200);
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(await api.getSessions(), isEmpty);
  });

  test('a 409 response throws an exception with the API message', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'status': 409, 'message': 'Session with id 2 is closed'}),
        409,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(
      api.joinSession(
        2,
        name: 'Asha',
        email: 'asha@example.com',
        topic: 'Arrays',
        question: 'How do I loop?',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Session with id 2 is closed'),
        ),
      ),
    );
  });

  test('getCurrentDoubt returns the in-progress doubt', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/current');
      return http.Response(
        jsonEncode({
          'id': 7,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do loops work?',
          'status': 'IN_PROGRESS',
          'position': null,
          'created_at': '2026-01-01 10:05:00',
          'started_at': '2026-01-01 10:10:00',
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.getCurrentDoubt(1);

    expect(doubt, isNotNull);
    expect(doubt!.id, 7);
    expect(doubt.studentName, 'Asha');
    expect(doubt.status, 'IN_PROGRESS');
  });

  test('getCurrentDoubt returns null when no doubt is in progress', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions/1/current');
      return http.Response(
        jsonEncode({
          'status': 404,
          'message': 'Session with id 1 has no doubt in progress',
        }),
        404,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(await api.getCurrentDoubt(1), isNull);
  });
}
