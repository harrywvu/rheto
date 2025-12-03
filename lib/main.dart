import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rheto/AppTheme.dart';
import 'package:rheto/screens/assessment_screen.dart';
import 'package:rheto/screens/auth_screen.dart';
import 'package:rheto/screens/home_screen.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000';

  ScoringService.setBaseUrl(backendUrl);
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

class _MyHomePageState extends State<MyHomePage> {
  late Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _getInitialScreen();
  }

  Future<Widget> _getInitialScreen() async {
    try {
      // Check if user has completed assessment
      final hasCompleted = await ScoreStorageService.hasCompletedAssessment();
      if (hasCompleted) {
        return const HomeScreen();
      } else {
        return const AuthScreen();
      }
    } catch (e) {
      // On error, show welcome screen
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return const AuthScreen();
          }
        } else {
          // Show loading while determining initial screen
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
              ),
            ),
          );
        }
      },
    );
  }
}
