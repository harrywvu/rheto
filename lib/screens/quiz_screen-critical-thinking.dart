import 'package:flutter/material.dart';
import 'package:rheto/models/question.dart';
import 'package:rheto/models/questions.dart';

class QuizScreen_Critical_Thinking extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(Map<String, dynamic>)? onDataCollected;
  const QuizScreen_Critical_Thinking({
    super.key,
    required this.onComplete,
    this.onDataCollected,
  });

  @override
  State<QuizScreen_Critical_Thinking> createState() =>
      _QuizScreen_Critical_Thinking_State();
}

class _QuizScreen_Critical_Thinking_State
    extends State<QuizScreen_Critical_Thinking> {
  int currentQuestionIndex = 0;
  Map<String, dynamic> userAnswers = {
    // questionId -> answer
    // logic_1 -> 2
  };
  
  // Track selected cognitive reflection question for justification
  String? selectedReflectionQuestionId;

  final TextEditingController _textController = TextEditingController();

  void _nextQuestion() {
    if (currentQuestionIndex < criticalThinkingQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _textController.clear();
      });
    } else {
      _goToNextStep();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        // Restore previous answer if exists
        final currentQ = criticalThinkingQuestions[currentQuestionIndex];
        if (userAnswers.containsKey(currentQ.id)) {
          if (currentQ.type == QuestionType.textInput ||
              currentQ.type == QuestionType.longText) {
            _textController.text = userAnswers[currentQ.id]?.toString() ?? '';
          }
        }
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      userAnswers[criticalThinkingQuestions[currentQuestionIndex].id] = answerIndex;
    });
  }

  void _saveTextAnswer(String text) {
    setState(() {
      userAnswers[criticalThinkingQuestions[currentQuestionIndex].id] = text;
    });
  }

  // increase 
  void _goToNextStep() {
    // Pass collected data back to parent, including selected reflection question
    if (widget.onDataCollected != null) {
      widget.onDataCollected!({
        ...userAnswers,
        'selectedReflectionQuestionId': selectedReflectionQuestionId,
      });
    }
    widget.onComplete();
  }

  double _calculateSimpleScore() {
    int correct = 0;
    for (var question in criticalThinkingQuestions) {
      if (question.category == QuestionCategory.justification) continue;

      final userAnswer = userAnswers[question.id];
      if (userAnswer == null) continue;

      if (question.type == QuestionType.multipleChoice) {
        if (userAnswer == question.correctAnswerIndex) correct++;
      } else if (question.type == QuestionType.textInput) {
        final normalizedAnswer = userAnswer.toString().toLowerCase().trim();
        final isCorrect =
            question.acceptableAnswers?.any(
              (acceptable) =>
                  acceptable.toLowerCase().trim() == normalizedAnswer,
            ) ??
            false;
        if (isCorrect) correct++;
      }
    }
    return correct.toDouble();
  }

  // CHECKS IF USER: 
  //  CAN PROCEED WITH THE QUESTIONS
  //  IS ON THE LAST QUESTION 
  bool _canProceed() {
    final currentQ = criticalThinkingQuestions[currentQuestionIndex];
    
    // For justification questions, also check if a reflection question is selected
    if (currentQ.category == QuestionCategory.justification) {
      return selectedReflectionQuestionId != null &&
          userAnswers.containsKey(currentQ.id) &&
          (userAnswers[currentQ.id]?.toString().trim().isNotEmpty ?? false);
    }
    
    return userAnswers.containsKey(currentQ.id) &&
        (userAnswers[currentQ.id]?.toString().trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = criticalThinkingQuestions[currentQuestionIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Question X of quiz.length"
            // "Question 1 of 10"
            Text(
              'Question ${currentQuestionIndex + 1} of ${criticalThinkingQuestions.length}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
            ),

            SizedBox(height: 8),

            LinearProgressIndicator(
              value:
                  (currentQuestionIndex + 1) / criticalThinkingQuestions.length,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74C0FC)),
            ),
          ],
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),

                // Category badge
                // [Logic Question] or [Fallacy Detection] or [Justification]
                Chip(
                  label: Text(_getCategoryLabel(currentQuestion.category)),
                  backgroundColor: _getCategoryColor(currentQuestion.category),
                ),

                SizedBox(height: 16),

                // Question text
                Text(
                  currentQuestion.question,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Lettera',
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 24),

                // Answer options based on question type
                _buildAnswerWidget(currentQuestion),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentQuestionIndex > 0)
              TextButton.icon(
                onPressed: _previousQuestion,
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white
                ),
              )
            else
              SizedBox.shrink(),

            ElevatedButton(
              onPressed: _canProceed() ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008000),
              ),
              child: Text(
                currentQuestionIndex < criticalThinkingQuestions.length - 1
                    ? 'Next'
                    : 'Finish',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerWidget(Question question) {
    // Special handling for justification questions
    if (question.category == QuestionCategory.justification) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Cognitive Reflection question to expand on:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'Lettera',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedReflectionQuestionId,
            hint: Text('Choose a question...'),
            items: cognitiveReflectionQuestions.map((q) {
              return DropdownMenuItem<String>(
                value: q.id,
                child: Text(
                  q.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Lettera',
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedReflectionQuestionId = value;
              });
            },
          ),
          if (selectedReflectionQuestionId != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF63E6BE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF63E6BE),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your answer to this question:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userAnswers[selectedReflectionQuestionId] ?? 'No answer provided',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Lettera',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Now expand on your reasoning:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Lettera',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _textController,
            onChanged: _saveTextAnswer,
            maxLines: 6,
            maxLength: question.maxLength,
            decoration: InputDecoration(
              hintText: 'Explain your reasoning in 2-3 sentences...',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF74C0FC), width: 2),
              ),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
          ),
        ],
      );
    }
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        return Column(
          children: List.generate(question.options!.length, (index) {
            final isSelected = userAnswers[question.id] == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _selectAnswer(index),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Color(0xFF74C0FC) : Colors.grey[700]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Color(0xFF74C0FC).withOpacity(0.1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Color(0xFF74C0FC)
                                : Colors.grey[600]!,
                            width: 2,
                          ),
                          color: isSelected ? Color(0xFF74C0FC) : null,
                        ),
                        // the content inside the circles
                        // if selected -> ✓ : else none
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options![index],
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontFamily: 'Lettera'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );

      case QuestionType.textInput:
        return TextField(
          controller: _textController,
          onChanged: _saveTextAnswer,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF74C0FC), width: 2),
            ),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
        );

      case QuestionType.longText:
        return TextField(
          controller: _textController,
          onChanged: _saveTextAnswer,
          maxLines: 6,
          maxLength: question.maxLength,
          decoration: InputDecoration(
            hintText: 'Explain your reasoning in 2-3 sentences...',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF74C0FC), width: 2),
            ),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
        );

      default:
        return Text('Unknown question type');
    }
  }

  String _getCategoryLabel(QuestionCategory category) {
    switch (category) {
      case QuestionCategory.logic:
        return 'Logic Challenge';
      case QuestionCategory.biasDetection:
        return 'Bias Detection';
      case QuestionCategory.cognitiveReflection:
        return 'Cognitive Reflection';
      case QuestionCategory.justification:
        return 'Justification';
    }
  }

  Color _getCategoryColor(QuestionCategory category) {
    switch (category) {
      case QuestionCategory.logic:
        return Color(0xFF74C0FC).withOpacity(0.3);
      case QuestionCategory.biasDetection:
        return Color(0xFFFFD43B).withOpacity(0.3);
      case QuestionCategory.cognitiveReflection:
        return Color(0xFF63E6BE).withOpacity(0.3);
      case QuestionCategory.justification:
        return Color(0xFFFF6B6B).withOpacity(0.3);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
