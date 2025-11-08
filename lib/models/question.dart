enum QuestionType { 
  multipleChoice, 
  textInput, 
  longText 
}

enum QuestionCategory {
  logic,
  biasDetection,
  cognitiveReflection,
  justification,
}

class Question {
  final String id;
  final QuestionType type;
  final QuestionCategory category;
  final String question;

// if question is multipleChoice
  final List<String>? options;
// index always starts at 0
  final int? correctAnswerIndex;


  final String? correctTextAnswer;
  final List<String>? acceptableAnswers;

  final int? maxLength;

  const Question({
    required this.id,
    required this.type,
    required this.category,
    required this.question,
    this.options,
    this.correctAnswerIndex,
    this.correctTextAnswer,
    this.acceptableAnswers,
    this.maxLength,
  });
}