import 'package:flutter/material.dart';
import 'package:rheto/main.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyApp(),
                          ),
                        );
                      },
                      child: const Text('Go Back'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF500073),
                      ),
                    ),
                  ],
                ),

                Text(
                  'Welcome to the assessment screen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
                )
              ],


            )
          ],
        )
      )
    );
  }
}

