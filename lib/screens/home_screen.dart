import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'domain_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, double>> _scoresFuture;

  @override
  void initState() {
    super.initState();
    _scoresFuture = ScoreStorageService.getScores();
  }

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
      body: FutureBuilder<Map<String, double>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Error loading scores'));
          }

          final scores = snapshot.data!;
          final criticalThinking = scores['criticalThinking'] ?? 0.0;
          final memory = scores['memory'] ?? 0.0;
          final creativity = scores['creativity'] ?? 0.0;
          final average = (criticalThinking + memory + creativity) / 3;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Your Dashboard',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontFamily: 'Ntype82-R'),
                ),
                SizedBox(height: 24),

                // Domain Stats Navbar
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        icon: FontAwesomeIcons.gears,
                        iconColor: Color(0xFF74C0FC),
                        label: 'Critical',
                        score: criticalThinking,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      _buildStatItem(
                        context,
                        icon: FontAwesomeIcons.lightbulb,
                        iconColor: Color(0xFFFFD43B),
                        label: 'Memory',
                        score: memory,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      _buildStatItem(
                        context,
                        icon: FontAwesomeIcons.squareShareNodes,
                        iconColor: Color(0xFF63E6BE),
                        label: 'Creativity',
                        score: creativity,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Overall Score
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
                        '${average.toStringAsFixed(1)}/100',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontFamily: 'NType82-R',
                              color: _getScoreColor(average),
                              fontSize: 48,
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getScoreLevel(average),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Lettera',
                              color: _getScoreColor(average),
                            ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Cognitive Profile',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Ntype82-R',
                              ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Click on any domain below to learn how your scores are calculated.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'Lettera',
                                color: Colors.grey[500],
                              ),
                        ),
                        SizedBox(height: 24),
                        // Domain Cards
                        _buildDomainCard(
                          context,
                          icon: FontAwesomeIcons.gears,
                          iconColor: Color(0xFF74C0FC),
                          title: 'Critical Thinking Index',
                          score: criticalThinking,
                          description: 'Logic, reasoning, and bias detection',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DomainDetailScreen(domain: 'critical_thinking'),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        _buildDomainCard(
                          context,
                          icon: FontAwesomeIcons.lightbulb,
                          iconColor: Color(0xFFFFD43B),
                          title: 'Memory Efficiency Score',
                          score: memory,
                          description: 'Recall accuracy and retention',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DomainDetailScreen(domain: 'memory'),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        _buildDomainCard(
                          context,
                          icon: FontAwesomeIcons.squareShareNodes,
                          iconColor: Color(0xFF63E6BE),
                          title: 'Creativity Studio',
                          score: creativity,
                          description: 'Divergent thinking and originality',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DomainDetailScreen(domain: 'creativity'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required double score,
  }) {
    return Column(
      children: [
        FaIcon(
          icon,
          color: iconColor,
          size: 20,
        ),
        SizedBox(height: 8),
        Text(
          '${score.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'NType82-R',
                color: _getScoreColor(score),
              ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.grey[500],
              ),
        ),
      ],
    );
  }

  Widget _buildDomainCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double score,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
