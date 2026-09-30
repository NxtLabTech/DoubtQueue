import 'package:doubtqueue/models/session.dart';
import 'package:doubtqueue/utils/session_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Session session(
  int id,
  String title, {
  String mentor = 'Priya',
  String status = 'OPEN',
  int waiting = 0,
  DateTime? createdAt,
}) {
  return Session(
    id: id,
    title: title,
    mentorName: mentor,
    status: status,
    waitingCount: waiting,
    createdAt: createdAt ?? DateTime.utc(2026, 1, id),
  );
}

List<int> ids(List<Session> sessions) => sessions.map((s) => s.id).toList();

void main() {
  final sessions = [
    session(1, 'PHP Basics', mentor: 'Priya', waiting: 2),
    session(2, 'Flutter Layouts', mentor: 'Arjun', waiting: 7),
    session(3, 'SQL Practice', mentor: 'Priya', waiting: 4, status: 'CLOSED'),
    session(4, 'Dart Async', mentor: 'Meera', waiting: 0),
  ];

  group('search', () {
    test('matches the session title', () {
      final result = filterSessions(sessions, query: 'flutter');
      expect(ids(result), [2]);
    });

    test('matches the mentor name', () {
      final result = filterSessions(
        sessions,
        query: 'PRIYA',
        status: SessionStatusFilter.all,
      );
      expect(ids(result), containsAll([1, 3]));
      expect(result, hasLength(2));
    });

    test('an empty search returns every session in the filter', () {
      expect(filterSessions(sessions, query: '  '), hasLength(3));
    });

    test('returns nothing when there is no match', () {
      expect(filterSessions(sessions, query: 'python'), isEmpty);
    });
  });

  group('status filter', () {
    test('open shows only open sessions', () {
      expect(ids(filterSessions(sessions)), [4, 2, 1]);
    });

    test('closed shows only closed sessions', () {
      final result = filterSessions(
        sessions,
        status: SessionStatusFilter.closed,
      );
      expect(ids(result), [3]);
    });

    test('all shows open sessions before closed ones', () {
      final result = filterSessions(sessions, status: SessionStatusFilter.all);
      expect(ids(result), [4, 2, 1, 3]);
    });
  });

  group('sorting', () {
    test('newest puts the latest created session first', () {
      final result = filterSessions(sessions, sort: SessionSort.newest);
      expect(ids(result), [4, 2, 1]);
    });

    test('most waiting puts the longest queue first', () {
      final result = filterSessions(sessions, sort: SessionSort.mostWaiting);
      expect(ids(result), [2, 1, 4]);
    });

    test('most waiting falls back to newest when counts are equal', () {
      final equal = [session(1, 'A', waiting: 3), session(2, 'B', waiting: 3)];
      final result = filterSessions(equal, sort: SessionSort.mostWaiting);
      expect(ids(result), [2, 1]);
    });
  });
}
