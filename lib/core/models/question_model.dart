class QuestionModel {
  final String id;
  final String courseId;
  final String questionText;
  final List<String> choices;
  final int correctAnswerIndex;
  final String difficulty; // 'easy', 'medium', 'hard'
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.courseId,
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      questionText: json['questionText'] ?? '',
      choices: List<String>.from(json['choices'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      difficulty: json['difficulty'] ?? 'medium',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'questionText': questionText,
      'choices': choices,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}