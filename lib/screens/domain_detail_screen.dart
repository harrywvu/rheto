import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/services/score_storage_service.dart';

class DomainDetailScreen extends StatefulWidget {
  final String domain;

  const DomainDetailScreen({super.key, required this.domain});

  @override
  State<DomainDetailScreen> createState() => _DomainDetailScreenState();
}

class _DomainDetailScreenState extends State<DomainDetailScreen> {
  late Future<Map<String, double>> _scoresFuture;
  late Future<Map<String, Map<String, double>>> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _scoresFuture = ScoreStorageService.getScores();
    _metricsFuture = ScoreStorageService.getMetrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh scores and metrics when returning from activities
    _scoresFuture = ScoreStorageService.getScores();
    _metricsFuture = ScoreStorageService.getMetrics();
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
          final score = _getScoreForDomain(snapshot.data ?? {});

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                    ),
                    Text(
                      _getDomainTitle(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Domain Score Card
                _buildDomainScoreCard(context, score),
                SizedBox(height: 24),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildDomainContent(context)],
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

  double _getScoreForDomain(Map<String, double> scores) {
    switch (widget.domain) {
      case 'critical_thinking':
        return scores['criticalThinking'] ?? 0.0;
      case 'memory':
        return scores['memory'] ?? 0.0;
      case 'creativity':
        return scores['creativity'] ?? 0.0;
      default:
        return 0.0;
    }
  }

  IconData _getDomainIcon() {
    switch (widget.domain) {
      case 'critical_thinking':
        return FontAwesomeIcons.gears;
      case 'memory':
        return FontAwesomeIcons.lightbulb;
      case 'creativity':
        return FontAwesomeIcons.squareShareNodes;
      default:
        return FontAwesomeIcons.question;
    }
  }

  Color _getDomainIconColor() {
    switch (widget.domain) {
      case 'critical_thinking':
        return Color(0xFF74C0FC);
      case 'memory':
        return Color(0xFFFFD43B);
      case 'creativity':
        return Color(0xFF63E6BE);
      default:
        return Colors.grey;
    }
  }

  String _getDomainTitle() {
    switch (widget.domain) {
      case 'critical_thinking':
        return 'Critical Thinking Index';
      case 'memory':
        return 'Memory Efficiency Score';
      case 'creativity':
        return 'Creativity Studio';
      default:
        return 'Domain Details';
    }
  }

  Widget _buildDomainScoreCard(BuildContext context, double score) {
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
              color: _getDomainIconColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              _getDomainIcon(),
              color: _getDomainIconColor(),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDomainTitle(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                ),
                SizedBox(height: 4),
                Text(
                  _getDomainDescription(),
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

  String _getDomainDescription() {
    switch (widget.domain) {
      case 'critical_thinking':
        return 'Logic, reasoning, and bias detection';
      case 'memory':
        return 'Recall accuracy and retention';
      case 'creativity':
        return 'Divergent thinking and originality';
      default:
        return '';
    }
  }

  Widget _buildDomainContent(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildDefaultContent(context);
        }

        final allMetrics = snapshot.data!;
        final metrics = _getMetricsForDomain(allMetrics);

        if (metrics.isEmpty) {
          return _buildDefaultContent(context);
        }

        return _buildMetricsDisplay(context, metrics);
      },
    );
  }

  Map<String, double> _getMetricsForDomain(
    Map<String, Map<String, double>> allMetrics,
  ) {
    switch (widget.domain) {
      case 'critical_thinking':
        return allMetrics['criticalThinking'] ?? {};
      case 'memory':
        return allMetrics['memory'] ?? {};
      case 'creativity':
        return allMetrics['creativity'] ?? {};
      default:
        return {};
    }
  }

  Widget _buildMetricsDisplay(
    BuildContext context,
    Map<String, double> metrics,
  ) {
    // Filter out old "Refinement" metric for creativity
    final displayMetrics = widget.domain == 'creativity'
        ? Map.fromEntries(metrics.entries.where((e) => e.key != 'Refinement'))
        : metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Your Performance Metrics'),
        SizedBox(height: 20),
        _buildMetricsGrid(context, displayMetrics),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'Detailed Breakdown'),
        SizedBox(height: 16),
        ...displayMetrics.entries.map((entry) {
          return _buildMetricBar(context, entry.key, entry.value);
        }).toList(),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'About This Domain'),
        SizedBox(height: 16),
        _buildDomainExplanation(context),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, double> metrics) {
    // Filter out old "Refinement" metric for creativity (keep only the 4 new metrics)
    final filteredMetrics = widget.domain == 'creativity'
        ? Map.fromEntries(metrics.entries.where((e) => e.key != 'Refinement'))
        : metrics;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: filteredMetrics.entries.map((entry) {
        return _buildMetricCard(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildMetricCard(BuildContext context, String name, double value) {
    final color = _getMetricColor(value);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${value.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'NType82-R',
              color: color,
              fontSize: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(BuildContext context, String name, double value) {
    final color = _getMetricColor(value);
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Ntype82-R',
                  color: Colors.grey[300],
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'NType82-R',
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMetricColor(double value) {
    if (value >= 80) return Color(0xFF63E6BE); // Green
    if (value >= 60) return Color(0xFF74C0FC); // Blue
    if (value >= 40) return Color(0xFFFF922B); // Orange
    return Color(0xFFFF6B6B); // Red
  }

  Widget _buildDomainExplanation(BuildContext context) {
    switch (widget.domain) {
      case 'critical_thinking':
        return Text(
          'Your Critical Thinking Index evaluates your ability to analyze information, identify logical patterns, detect biases, and provide well-reasoned explanations. A higher score indicates stronger analytical and reasoning capabilities.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
            height: 1.6,
          ),
        );
      case 'memory':
        return Text(
          'Your Memory Efficiency Score reflects how well you can encode, store, and retrieve information. It combines accuracy with speed and retention patterns to give a comprehensive view of your memory performance. Higher scores indicate better memory capacity and efficiency.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
            height: 1.6,
          ),
        );
      case 'creativity':
        return Text(
          'Your Creativity Studio score evaluates your divergent thinking abilities. It measures how many ideas you can generate, how diverse those ideas are, how original they are, and how well you can refine them. Higher scores indicate stronger creative thinking and innovation potential.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
            height: 1.6,
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildDefaultContent(BuildContext context) {
    switch (widget.domain) {
      case 'critical_thinking':
        return _buildCriticalThinkingContent(context);
      case 'memory':
        return _buildMemoryContent(context);
      case 'creativity':
        return _buildCreativityContent(context);
      default:
        return Center(child: Text('Unknown domain'));
    }
  }

  Widget _buildCriticalThinkingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'How Your Score is Calculated'),
        SizedBox(height: 16),
        _buildScoreFormula(
          context,
          formula: '80% Multiple Choice + 20% AI-Scored Justification',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'Key Metrics'),
        SizedBox(height: 16),
        _buildMetricItem(
          context,
          metric: 'Accuracy Rate',
          description:
              'Percentage of correct answers on multiple choice questions',
        ),
        _buildMetricItem(
          context,
          metric: 'Bias Detection Rate',
          description:
              'Ability to identify logical fallacies and cognitive biases',
        ),
        _buildMetricItem(
          context,
          metric: 'Cognitive Reflection',
          description:
              'Quality of your reasoning and justification for answers',
        ),
        _buildMetricItem(
          context,
          metric: 'Justification Quality',
          description: 'Clarity, depth, and logical structure of explanations',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'What This Measures'),
        SizedBox(height: 16),
        Text(
          'Your Critical Thinking Index evaluates your ability to analyze information, identify logical patterns, detect biases, and provide well-reasoned explanations. A higher score indicates stronger analytical and reasoning capabilities.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'How Your Score is Calculated'),
        SizedBox(height: 16),
        _buildScoreFormula(
          context,
          formula:
              '(Accuracy × Retention Curve Fit) ÷ (Average Recall Time / 10)',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'Key Metrics'),
        SizedBox(height: 16),
        _buildMetricItem(
          context,
          metric: 'Recall Accuracy',
          description: 'Percentage of items correctly recalled from memory',
        ),
        _buildMetricItem(
          context,
          metric: 'Recall Latency',
          description: 'Average time taken to retrieve information from memory',
        ),
        _buildMetricItem(
          context,
          metric: 'Retention Curve',
          description: 'How well you retain information over time',
        ),
        _buildMetricItem(
          context,
          metric: 'Item Mastery',
          description: 'Consistency and confidence in recalling specific items',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'What This Measures'),
        SizedBox(height: 16),
        Text(
          'Your Memory Efficiency Score reflects how well you can encode, store, and retrieve information. It combines accuracy with speed and retention patterns to give a comprehensive view of your memory performance. Higher scores indicate better memory capacity and efficiency.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildCreativityContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'How Your Score is Calculated'),
        SizedBox(height: 16),
        _buildScoreFormula(
          context,
          formula:
              '25% Fluency + 25% Flexibility + 25% Originality + 25% Refinement Gain',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'Key Metrics'),
        SizedBox(height: 16),
        _buildMetricItem(
          context,
          metric: 'Fluency',
          description: 'Number of ideas generated and ease of idea generation',
        ),
        _buildMetricItem(
          context,
          metric: 'Flexibility',
          description: 'Variety of different types and categories of ideas',
        ),
        _buildMetricItem(
          context,
          metric: 'Originality',
          description: 'Uniqueness and novelty of your ideas',
        ),
        _buildMetricItem(
          context,
          metric: 'Refinement Gain',
          description: 'Quality improvement and flow of ideas across domains',
        ),
        SizedBox(height: 32),
        _buildSectionTitle(context, 'What This Measures'),
        SizedBox(height: 16),
        Text(
          'Your Creativity Studio score evaluates your divergent thinking abilities. It measures how many ideas you can generate, how diverse those ideas are, how original they are, and how well you can refine them. Higher scores indicate stronger creative thinking and innovation potential.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
    );
  }

  Widget _buildScoreFormula(BuildContext context, {required String formula}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900],
      ),
      child: Text(
        formula,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'Lettera',
          color: Color(0xFF63E6BE),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String metric,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $metric',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
