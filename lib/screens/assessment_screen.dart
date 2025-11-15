import 'package:flutter/material.dart';
import 'package:rheto/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rheto/screens/quiz_screen-critical-thinking.dart';
import 'quiz_screen-memory-booster.dart';
import 'quiz_screen_creativity.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // startScreen = 0 : The initial screen for the assessment
  int currentStep = 0;

  Widget getStepWidget(int step) {
    switch (step) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'Think of this as a checkup!',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontFamily: 'Ntype82-R'),
                ),
                Text(
                  'This is to establish your baseline cognitive profile across three domains:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            Column(
              spacing: 8,
              children: [
                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.gears,
                    color: Color(0xFF74C0FC),
                    size: 20,
                  ),
                  label: Text("Critical Thinking"),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFF74C0FC)),
                  ),
                ),

                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.lightbulb,
                    color: Color(0xFFFFD43B),
                    size: 20,
                  ),
                  label: Text("Memory"),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFFFFD43B)),
                  ),
                ),

                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.squareShareNodes,
                    color: Color(0xFF63E6BE),
                    size: 20,
                  ),
                  label: Text("Creativity"),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFF63E6BE)),
                  ),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: () {
                // When pressed, the screen changes to the first activity.
                setState(() {
                  currentStep++;
                });
              },
              child: Text("Start"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008000),
                textStyle: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            Text(
              "This won't take long! 😊",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 1: // Critical Thinking Trainer
        return QuizScreen_Critical_Thinking(
          onComplete: () => {
            setState(() {
              currentStep++;
            }),
          },
        );
      case 2:
        return QuizScreenMemoryBooster(
          onComplete: () => {
            setState(() {
              currentStep++;
            }),
          },
        );
      case 3:
        return QuizScreenCreativity(
          onComplete: () => {
            setState(() {
              currentStep++;
            }),
          },
        );
      default:
        return Center(child: Text("The fuck are you doing here?"));
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // children is a list of widgets
            // 1st child of the column -> Return & subtitle screen
            Row(
              children: [
                // Press this to go back to home screen
                IconButton(
                  // iconSize: ,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                ),

                Text(
                  'Initial Assessment',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Second child of the column -> Welcome and Onboaring with Proceed Button
            // This is the child widget that changes when the elevated button is clicked.
            Expanded(child: getStepWidget(currentStep)),
          ],
        ),
      ),
    );
  }
}

Widget _buildResultScreen(context) {
  return Row(
    children: [
      Text(
        "Results",
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
      ),
    ],
  );
}
