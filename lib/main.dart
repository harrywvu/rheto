import 'package:flutter/material.dart';
import 'package:rheto/AppTheme.dart';
import 'package:rheto/screens/assessment_screen.dart';
import 'package:rheto/screens/auth_screen.dart';
import 'package:rheto/screens/home_screen.dart';
import 'package:rheto/services/auth_service.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/services/notification_service.dart';
import 'package:rheto/services/background_metric_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ScoringService.setBaseUrl('http://192.168.100.208:3000');
  await NotificationService().initialize();

  // Initialize Supabase
  await supabase.Supabase.initialize(
    url: 'https://jrtxcoyxswegciqmjniw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpydHhjb3l4c3dlZ2NpcW1qbml3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzODcyNjYsImV4cCI6MjA3OTk2MzI2Nn0.oh-o0b3yau98v18PUe_UiX4M7Lg22Kpmzz7a2yxA6WQ',
  );

  // Initialize background service for daily metric snapshots
  await BackgroundMetricService.initializeBackgroundService();

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
      // Give Supabase a moment to fully initialize
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if user has an active session
      final hasSession = AuthService.hasSession;
      if (hasSession) {
        // Session exists, check assessment status
        final hasCompleted = await ScoreStorageService.hasCompletedAssessment();
        return hasCompleted ? const HomeScreen() : AssessmentScreen();
      } else {
        // No session, go to auth screen
        return const AuthScreen();
      }
    } catch (e) {
      // On error, show auth screen
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
