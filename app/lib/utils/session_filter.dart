import '../models/session.dart';

enum SessionStatusFilter { open, closed, all }

enum SessionSort { newest, mostWaiting }

List<Session> filterSessions(
  List<Session> sessions, {
  String query = '',
  SessionStatusFilter status = SessionStatusFilter.open,
  SessionSort sort = SessionSort.newest,
}) {
  final text = query.trim().toLowerCase();

  final result = sessions.where((session) {
    return _matchesStatus(session, status) && _matchesQuery(session, text);
  }).toList();

  result.sort((a, b) => _compare(a, b, sort, status));
  return result;
}

bool _matchesStatus(Session session, SessionStatusFilter status) {
  switch (status) {
    case SessionStatusFilter.open:
      return session.isOpen;
    case SessionStatusFilter.closed:
      return !session.isOpen;
    case SessionStatusFilter.all:
      return true;
  }
}

bool _matchesQuery(Session session, String text) {
  return session.title.toLowerCase().contains(text) ||
      session.mentorName.toLowerCase().contains(text);
}

int _compare(
  Session a,
  Session b,
  SessionSort sort,
  SessionStatusFilter status,
) {
  if (status == SessionStatusFilter.all && a.isOpen != b.isOpen) {
    return a.isOpen ? -1 : 1;
  }
  if (sort == SessionSort.mostWaiting && a.waitingCount != b.waitingCount) {
    return b.waitingCount.compareTo(a.waitingCount);
  }
  return _compareNewest(a, b);
}

int _compareNewest(Session a, Session b) {
  final aTime = a.createdAt;
  final bTime = b.createdAt;
  if (aTime != null && bTime != null && aTime != bTime) {
    return bTime.compareTo(aTime);
  }
  return b.id.compareTo(a.id);
}
