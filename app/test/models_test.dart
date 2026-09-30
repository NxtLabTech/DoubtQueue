import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Session.fromJson reads all fields', () {
    final session = Session.fromJson({
      'id': 3,
      'title': 'PHP Basics Doubt Session',
      'mentor_name': 'Priya',
      'status': 'OPEN',
      'created_at': '2026-01-01 10:00:00',
      'closed_at': null,
      'waiting_count': 5,
    });

    expect(session.id, 3);
    expect(session.title, 'PHP Basics Doubt Session');
    expect(session.mentorName, 'Priya');
    expect(session.isOpen, isTrue);
    expect(session.waitingCount, 5);
  });

  test('Doubt.fromJson reads a waiting doubt with a position', () {
    final doubt = Doubt.fromJson({
      'id': 8,
      'session_id': 3,
      'student_name': 'Asha',
      'student_email': 'asha@example.com',
      'topic': 'Arrays',
      'question': 'How do I loop over an array?',
      'status': 'WAITING',
      'position': 2,
    });

    expect(doubt.id, 8);
    expect(doubt.sessionId, 3);
    expect(doubt.studentName, 'Asha');
    expect(doubt.isWaiting, isTrue);
    expect(doubt.position, 2);
  });

  test('Doubt.fromJson accepts a null position', () {
    final doubt = Doubt.fromJson({
      'id': 9,
      'session_id': 3,
      'student_name': 'Ben',
      'student_email': 'ben@example.com',
      'topic': 'PDO',
      'question': 'What is a prepared statement?',
      'status': 'SOLVED',
      'position': null,
    });

    expect(doubt.position, isNull);
    expect(doubt.isFinished, isTrue);
  });
}
