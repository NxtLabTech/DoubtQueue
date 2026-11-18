import 'dart:convert';

import 'package:doubtqueue/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const baseUrl = 'http://test.local';

  test('getSessions returns sessions from the API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
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

  test('createSession sends expected request and parses session', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), '$baseUrl/api/sessions');
      expect(request.headers['Content-Type'], 'application/json');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['title'], 'PHP Basics Doubt Session');
      expect(body['mentor_name'], 'Priya');

      return http.Response(
        jsonEncode({
          'id': 1,
          'title': 'PHP Basics Doubt Session',
          'mentor_name': 'Priya',
          'status': 'OPEN',
          'waiting_count': 0,
        }),
        201,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final session = await api.createSession(
      'PHP Basics Doubt Session',
      'Priya',
    );

    expect(session.id, 1);
    expect(session.title, 'PHP Basics Doubt Session');
    expect(session.mentorName, 'Priya');
    expect(session.isOpen, isTrue);
    expect(session.waitingCount, 0);
  });

  test('closeSession sends PATCH request and parses updated session', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/close');
      return http.Response(
        jsonEncode({
          'id': 1,
          'title': 'PHP Basics Doubt Session',
          'mentor_name': 'Priya',
          'status': 'CLOSED',
          'waiting_count': 0,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final session = await api.closeSession(1);

    expect(session.id, 1);
    expect(session.isOpen, isFalse);
    expect(session.status, 'CLOSED');
  });

  test('joinSession sends expected request and parses doubt', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/doubts');
      expect(request.headers['Content-Type'], 'application/json');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['student_name'], 'Asha');
      expect(body['student_email'], 'asha@example.com');
      expect(body['topic'], 'Arrays');
      expect(body['question'], 'How do I loop over an array?');

      return http.Response(
        jsonEncode({
          'id': 10,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do I loop over an array?',
          'status': 'WAITING',
          'position': 3,
        }),
        201,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.joinSession(
      1,
      name: 'Asha',
      email: 'asha@example.com',
      topic: 'Arrays',
      question: 'How do I loop over an array?',
    );

    expect(doubt.id, 10);
    expect(doubt.sessionId, 1);
    expect(doubt.studentName, 'Asha');
    expect(doubt.studentEmail, 'asha@example.com');
    expect(doubt.topic, 'Arrays');
    expect(doubt.question, 'How do I loop over an array?');
    expect(doubt.isWaiting, isTrue);
    expect(doubt.position, 3);
    expect(doubt.studentsAhead, 2);
  });

  test('getQueue sends GET request and returns queue doubts', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/queue');
      return http.Response(
        jsonEncode([
          {
            'id': 10,
            'session_id': 1,
            'student_name': 'Asha',
            'student_email': 'asha@example.com',
            'topic': 'Arrays',
            'question': 'How do I loop?',
            'status': 'WAITING',
            'position': 1,
          },
          {
            'id': 11,
            'session_id': 1,
            'student_name': 'Ben',
            'student_email': 'ben@example.com',
            'topic': 'PDO',
            'question': 'Prepared statement?',
            'status': 'WAITING',
            'position': 2,
          },
        ]),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final queue = await api.getQueue(1);

    expect(queue, hasLength(2));
    expect(queue.first.id, 10);
    expect(queue.first.studentName, 'Asha');
    expect(queue.first.position, 1);
    expect(queue.last.id, 11);
    expect(queue.last.studentName, 'Ben');
    expect(queue.last.position, 2);
  });

  test('takeNext sends POST request and returns next doubt', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/next');
      return http.Response(
        jsonEncode({
          'id': 10,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do I loop?',
          'status': 'IN_PROGRESS',
          'position': null,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.takeNext(1);

    expect(doubt.id, 10);
    expect(doubt.status, 'IN_PROGRESS');
    expect(doubt.studentName, 'Asha');
    expect(doubt.position, isNull);
  });

  test('getStats sends GET request and parses all four status counts', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), '$baseUrl/api/sessions/1/stats');
      return http.Response(
        jsonEncode({
          'WAITING': 4,
          'IN_PROGRESS': 1,
          'SOLVED': 6,
          'SKIPPED': 2,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final stats = await api.getStats(1);

    expect(stats, {
      'WAITING': 4,
      'IN_PROGRESS': 1,
      'SOLVED': 6,
      'SKIPPED': 2,
    });
    expect(stats['WAITING'], 4);
    expect(stats['IN_PROGRESS'], 1);
    expect(stats['SOLVED'], 6);
    expect(stats['SKIPPED'], 2);
  });

  test('getDoubt sends GET request and returns doubt details', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), '$baseUrl/api/doubts/10');
      return http.Response(
        jsonEncode({
          'id': 10,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do I loop?',
          'status': 'WAITING',
          'position': 3,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.getDoubt(10);

    expect(doubt.id, 10);
    expect(doubt.sessionId, 1);
    expect(doubt.studentName, 'Asha');
    expect(doubt.topic, 'Arrays');
    expect(doubt.position, 3);
    expect(doubt.studentsAhead, 2);
  });

  test('markSolved sends PATCH request and returns solved doubt', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.toString(), '$baseUrl/api/doubts/10/solved');
      return http.Response(
        jsonEncode({
          'id': 10,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do I loop?',
          'status': 'SOLVED',
          'position': null,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.markSolved(10);

    expect(doubt.id, 10);
    expect(doubt.status, 'SOLVED');
    expect(doubt.isFinished, isTrue);
  });

  test('markSkipped sends PATCH request and returns skipped doubt', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.toString(), '$baseUrl/api/doubts/10/skipped');
      return http.Response(
        jsonEncode({
          'id': 10,
          'session_id': 1,
          'student_name': 'Asha',
          'student_email': 'asha@example.com',
          'topic': 'Arrays',
          'question': 'How do I loop?',
          'status': 'SKIPPED',
          'position': null,
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final doubt = await api.markSkipped(10);

    expect(doubt.id, 10);
    expect(doubt.status, 'SKIPPED');
    expect(doubt.isFinished, isTrue);
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

  test(
    'a 404 response containing a JSON error body preserves its message',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'status': 404, 'message': 'Doubt with id 99 not found'}),
          404,
        );
      });
      final api = ApiService(client, baseUrl: baseUrl);

      expect(
        api.getDoubt(99),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Doubt with id 99 not found',
          ),
        ),
      );
    },
  );

  test(
    'a 500 response with a non-JSON body throws status code exception',
    () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final api = ApiService(client, baseUrl: baseUrl);

      expect(
        api.getSessions(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Request failed with status 500',
          ),
        ),
      );
    },
  );
}
