import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final double criticalThinkingScore;
  final double memoryScore;
  final double creativityScore;
  final VoidCallback onReturnHome;

  const ResultsScreen({
    super.key,
    required this.criticalThinkingScore,
    required this.memoryScore,
    required this.creativityScore,
    required this.onReturnHome,
  });

  double get averageScore =>
      (criticalThinkingScore + memoryScore + creativityScore) / 3;

  String _getScoreLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Color(0xFF63E6BE); // Green
    if (score >= 60) return Color(0xFFFFD43B); // Yellow
    if (score >= 40) return Color(0xFFFF922B); // Orange
    return Color(0xFFFF6B6B); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Your Results',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontFamily: 'Ntype82-R'),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Overall Score Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Overall Baseline Score',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[400],
                        ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${averageScore.toStringAsFixed(1)}/100',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontFamily: 'NType82-R',
                          color: _getScoreColor(averageScore),
                          fontSize: 48,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getScoreLevel(averageScore),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Lettera',
                          color: _getScoreColor(averageScore),
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Domain Scores
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16,
                  children: [
                    _buildDomainCard(
                      context,
                      icon: FontAwesomeIcons.gears,
                      iconColor: Color(0xFF74C0FC),
                      title: 'Critical Thinking',
                      score: criticalThinkingScore,
                      description: 'Logic, reasoning, and bias detection',
                    ),
                    _buildDomainCard(
                      context,
                      icon: FontAwesomeIcons.lightbulb,
                      iconColor: Color(0xFFFFD43B),
                      title: 'Memory Efficiency',
                      score: memoryScore,
                      description: 'Recall accuracy and retention',
                    ),
                    _buildDomainCard(
                      context,
                      icon: FontAwesomeIcons.squareShareNodes,
                      iconColor: Color(0xFF63E6BE),
                      title: 'Creativity',
                      score: creativityScore,
                      description: 'Divergent thinking and originality',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Return Home Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Save scores to persistent storage
                  await ScoreStorageService.saveScores(
                    criticalThinkingScore: criticalThinkingScore,
                    memoryScore: memoryScore,
                    creativityScore: creativityScore,
                  );
                  
                  // Navigate to home screen
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008000),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Return to Home',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double score,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontFamily: 'Ntype82-R'),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Lettera',
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'NType82-R',
                      color: _getScoreColor(score),
                    ),
              ),
              Text(
                _getScoreLevel(score),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      color: _getScoreColor(score),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
