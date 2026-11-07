import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/doubt.dart';
import '../models/session.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._client, {this.baseUrl = apiBaseUrl});

  final http.Client _client;
  final String baseUrl;

  static const _invalidResponseMessage =
      'The server returned an unexpected response. Please try again.';

  Future<List<Session>> getSessions({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final data = await _send('GET', '/api/sessions$query');

    return _parseResponse(() {
      return (data as List<dynamic>)
          .map((item) => Session.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Session> createSession(String title, String mentorName) async {
    final data = await _send('POST', '/api/sessions', {
      'title': title,
      'mentor_name': mentorName,
    });

    return _parseResponse(() => Session.fromJson(data as Map<String, dynamic>));
  }

  Future<Session> closeSession(int sessionId) async {
    final data = await _send('PATCH', '/api/sessions/$sessionId/close');

    return _parseResponse(() => Session.fromJson(data as Map<String, dynamic>));
  }

  Future<Doubt> joinSession(
    int sessionId, {
    required String name,
    required String email,
    required String topic,
    required String question,
  }) async {
    final data = await _send('POST', '/api/sessions/$sessionId/doubts', {
      'student_name': name,
      'student_email': email,
      'topic': topic,
      'question': question,
    });

    return _parseResponse(() => Doubt.fromJson(data as Map<String, dynamic>));
  }

  Future<List<Doubt>> getQueue(int sessionId) async {
    final data = await _send('GET', '/api/sessions/$sessionId/queue');

    return _parseResponse(() {
      return (data as List<dynamic>)
          .map((item) => Doubt.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Doubt> takeNext(int sessionId) async {
    final data = await _send('POST', '/api/sessions/$sessionId/next');

    return _parseResponse(() => Doubt.fromJson(data as Map<String, dynamic>));
  }

  Future<Map<String, int>> getStats(int sessionId) async {
    final data = await _send('GET', '/api/sessions/$sessionId/stats');

    return _parseResponse(() {
      return (data as Map<String, dynamic>).map(
        (status, count) => MapEntry(status, count as int),
      );
    });
  }

  Future<Doubt> getDoubt(int doubtId) async {
    final data = await _send('GET', '/api/doubts/$doubtId');

    return _parseResponse(() => Doubt.fromJson(data as Map<String, dynamic>));
  }

  Future<Doubt> markSolved(int doubtId) async {
    final data = await _send('PATCH', '/api/doubts/$doubtId/solved');

    return _parseResponse(() => Doubt.fromJson(data as Map<String, dynamic>));
  }

  Future<Doubt> markSkipped(int doubtId) async {
    final data = await _send('PATCH', '/api/doubts/$doubtId/skipped');

    return _parseResponse(() => Doubt.fromJson(data as Map<String, dynamic>));
  }

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;

    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    dynamic decoded;

    try {
      decoded = _decode(response);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const ApiException(_invalidResponseMessage);
      }

      throw ApiException('Request failed with status ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic> && decoded['message'] is String) {
      throw ApiException(decoded['message'] as String);
    }

    throw ApiException('Request failed with status ${response.statusCode}');
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  T _parseResponse<T>(T Function() parser) {
    try {
      return parser();
    } on TypeError {
      throw const ApiException(_invalidResponseMessage);
    } on FormatException {
      throw const ApiException(_invalidResponseMessage);
    }
  }
}
