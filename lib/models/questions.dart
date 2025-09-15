import 'package:rheto/models/question.dart';

const List<Question> questions = [

  Question(
    question: 'All philosophers are thinkers. Some thinkers are skeptics. Which conclusion is logically valid?',
    options: [
      'All skeptics are philosophers',
      'Some philosophers are skeptics',
      'Some skeptics may be philosophers',
      'All thinkers are philosophers'
    ],
    correctAnswerIndex: 2,
  ),

  Question(
    question: 'If Anna studies, then she passes the exam. Anna did not pass the exam. What can we conclude?',
    options: [
      'Anna must not have studied',
      'Anna may have studied but still failed',
      'If Anna passed, then she studied',
      'No conclusion can be drawn'
    ],
    correctAnswerIndex: 0,
  ),

  Question(
    question: 'Every poet is imaginative. No unimaginative person is an artist. Which statement follows?',
    options: [
      'All artists are poets',
      'Some imaginative people are not poets',
      'All poets could be artists',
      'No poet is an artist'
    ],
    correctAnswerIndex: 2,
  ),

];
