class Session {
  const Session({
    required this.id,
    required this.title,
    required this.mentorName,
    required this.status,
    required this.waitingCount,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      title: json['title'] as String,
      mentorName: json['mentor_name'] as String,
      status: json['status'] as String,
      waitingCount: json['waiting_count'] as int? ?? 0,
    );
  }

  final int id;
  final String title;
  final String mentorName;
  final String status;
  final int waitingCount;

  bool get isOpen => status == 'OPEN';
}
