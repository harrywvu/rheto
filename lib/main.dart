import 'package:flutter/material.dart';
import 'package:rheto/AppTheme.dart';
import 'package:rheto/screens/assessment_screen.dart';
import 'package:rheto/screens/home_screen.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ScoringService.setBaseUrl('http://192.168.100.208:3000');
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  // All 'State*' widget needs a build method
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rheto',
      theme: AppTheme.darkTheme,
      home: const MyHomePage(title: 'Rheto'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// where the logic exists
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _checkAssessmentStatus();
  }

  void _checkAssessmentStatus() async {
    final hasCompleted = await ScoreStorageService.hasCompletedAssessment();
    if (hasCompleted && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.eco, size: 40, color: Colors.green),
                    const Image(
                      image: AssetImage('assets/icon/rheto.png'),
                      width: 70,
                      height: 70,
                    ),

                    const SizedBox(width: 12),
                    Text(
                      'Rheto',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                  ],
                ),

                Text(
                  'AI-Powered Neuroscience-Based Training App',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                Text(
                  'for Enhancing Critical Thinking, Memory, and Creativity.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssessmentScreen(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF500073),
                  ),

                  child: Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Take initial assessment before beginning',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            Text(
              'Welcome to Rheto',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
