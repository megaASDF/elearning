class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final Map<String, int> answers; // questionId -> selectedAnswerIndex
  final double score;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int attemptNumber;

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.answers,
    required this.score,
    required this.startedAt,
    this.submittedAt,
    required this.attemptNumber,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] ?? json['_id'] ?? '',
      quizId: json['quizId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      answers: Map<String, int>.from(json['answers'] ?? {}),
      score: (json['score'] ?? 0).toDouble(),
      startedAt: DateTime.parse(json['startedAt']),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      attemptNumber: json['attemptNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'answers': answers,
      'score': score,
      'startedAt': startedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'attemptNumber': attemptNumber,
    };
  }

  bool get isCompleted => submittedAt != null;
}