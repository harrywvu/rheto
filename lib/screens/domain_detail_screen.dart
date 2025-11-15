import 'package:flutter/material.dart';

class DomainDetailScreen extends StatelessWidget {
  final String domain;

  const DomainDetailScreen({
    super.key,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontFamily: 'Ntype82-R'),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDomainContent(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDomainTitle() {
    switch (domain) {
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

  Widget _buildDomainContent(BuildContext context) {
    switch (domain) {
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
          description: 'Percentage of correct answers on multiple choice questions',
        ),
        _buildMetricItem(
          context,
          metric: 'Bias Detection Rate',
          description: 'Ability to identify logical fallacies and cognitive biases',
        ),
        _buildMetricItem(
          context,
          metric: 'Cognitive Reflection',
          description: 'Quality of your reasoning and justification for answers',
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
          formula: '(Accuracy × Retention Curve Fit) ÷ (Average Recall Time / 10)',
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
          formula: '30% Fluency + 25% Flexibility + 25% Originality + 20% Refinement',
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
          description: 'Quality improvement from initial ideas to refined concept',
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
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
          ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Ntype82-R',
                ),
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
