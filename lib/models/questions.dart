import 'package:rheto/models/question.dart';

const List<Question> logicQuestions = [

  Question(
    id: 'logic_1',
    type: QuestionType.multipleChoice,
    category: QuestionCategory.logic,
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
    id: 'logic_2',
    type: QuestionType.multipleChoice,
    category: QuestionCategory.logic,
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
    id: 'logic_3',
    type: QuestionType.multipleChoice,
    category: QuestionCategory.logic,
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

const List<Question> biasDetectionQuestions = [

  Question(
    id: 'bias_detection_1',
    type: QuestionType.multipleChoice,
    category: QuestionCategory.biasDetection,
    question: '“This medication must work—it has thousands of 5-star reviews on social media.” Identify the bias:',
    options: [
      'Availability bias',
      'Bandwagon effect',
      'Authority bias',
      'Survivorship bias'
    ],
    correctAnswerIndex: 1,
  ),

  Question(
    id: 'bias_detection_2',
    type: QuestionType.multipleChoice,
    category: QuestionCategory.biasDetection,
    question: '“The research cannot be valid because it was funded by a tech company.” Identify the bias:',
    options: [
      'Ad hominem',
      'Framing effect',
      'Funding bias',
      'Genetic fallacy'
    ],
    correctAnswerIndex: 3,
  ),
];

const List<Question> cognitiveReflectionQuestions = [
  Question(
    id: 'reflection_1',
    type: QuestionType.textInput,
    category: QuestionCategory.cognitiveReflection,
    question: 'A lily pad doubles in size every day. In 48 days, the pond is fully covered.\nOn which day is it half covered?',
    correctTextAnswer: '47',
    acceptableAnswers: ['47', 'day 47', 'Day 47', '47th day'],
  ),
  Question(
    id: 'reflection_2',
    type: QuestionType.textInput,
    category: QuestionCategory.cognitiveReflection,
    question: 'In a race, you pass the runner in 2nd place.\nWhat position are you in now?',
    correctTextAnswer: '2nd',
    acceptableAnswers: ['2', '2nd', 'second', '2nd place', 'Second place'],
  ),
  Question(
    id: 'reflection_3',
    type: QuestionType.textInput,
    category: QuestionCategory.cognitiveReflection,
    question: 'A library has 20 identical books. Each book costs \$10, but a discount applies: for every 2 books purchased, 1 extra book is free.\nHow much does it cost to own all 20 books?',
    correctTextAnswer: '140',
    acceptableAnswers: ['140', '\$140', '140 dollars'],
  ),
  
];

const List<Question> justificationQuestions = [

  Question(
    id: 'justification_1',
    type: QuestionType.longText,
    category: QuestionCategory.justification,
    question: 'Choose one of your answers above. Explain your reasoning in 2\-\-3 sentences.',
    maxLength: 500,
  ),
];

final List<Question> criticalThinkingQuestions = [
  ...logicQuestions,
  ...biasDetectionQuestions,
  ...cognitiveReflectionQuestions,
  ...justificationQuestions,
];

final List<Question> memoryQuestions = [



];

final List<Question> creativityQuestions = [


  
];