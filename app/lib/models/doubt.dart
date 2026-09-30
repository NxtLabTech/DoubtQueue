class Doubt {
  const Doubt({
    required this.id,
    required this.sessionId,
    required this.studentName,
    required this.topic,
    required this.question,
    required this.status,
    this.position,
  });

  factory Doubt.fromJson(Map<String, dynamic> json) {
    return Doubt(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      studentName: json['student_name'] as String,
      topic: json['topic'] as String,
      question: json['question'] as String,
      status: json['status'] as String,
      position: json['position'] as int?,
    );
  }

  final int id;
  final int sessionId;
  final String studentName;
  final String topic;
  final String question;
  final String status;
  final int? position;

  bool get isWaiting => status == 'WAITING';
  bool get isFinished => status == 'SOLVED' || status == 'SKIPPED';
}
