import 'package:flutter/material.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/screens/assessment_screen.dart';
import 'package:rheto/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      // Check if user has completed assessment
      final hasCompleted = await ScoreStorageService.hasCompletedAssessment();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              hasCompleted ? const HomeScreen() : AssessmentScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to continue: $e',
            style: const TextStyle(fontFamily: 'Lettera'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
                ),
                Text(
                  'for Enhancing Critical Thinking, Memory, and Creativity.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'Lettera'),
                ),
              ],
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF500073),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Get Started',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontFamily: 'Ntype82-R'),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Take initial assessment before beginning',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'Lettera'),
                ),
              ],
            ),
            Text(
              'Welcome to Rheto',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
            ),
          ],
        ),
      ),
    );
  }
}
