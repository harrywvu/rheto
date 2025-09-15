import 'package:flutter/material.dart';
import '/models/questions.dart';

class QuizScreen_Critical_Thinking extends StatefulWidget {
  const QuizScreen_Critical_Thinking({super.key});

  @override
  State<QuizScreen_Critical_Thinking> createState() =>
      _QuizScreen_Critical_Thinking_State();
}

class _QuizScreen_Critical_Thinking_State extends  State<QuizScreen_Critical_Thinking>{

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        
      ),
    );
  }
}
