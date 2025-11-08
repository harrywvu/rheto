import 'package:flutter/material.dart';

class QuizScreenCreativity extends StatefulWidget {
  const QuizScreenCreativity({super.key});

  @override
  State<QuizScreenCreativity> createState() => _QuizScreenCreativityState();
}

class _QuizScreenCreativityState extends State<QuizScreenCreativity> {
  final Set<String> _userIdeas = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Container());
  }
}
