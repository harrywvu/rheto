import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/module.dart';

/// Reusable activity results dialog component
/// Displays metrics, rewards, and provides optional review functionality
class ActivityResultsDialog extends StatefulWidget {
  final String activityName;
  final double score;
  final UserProgress progress;
  final Map<String, dynamic> metrics;
  final VoidCallback onContinue;
  final VoidCallback? onReview;
  final List<Widget>? customActions;

  const ActivityResultsDialog({
    Key? key,
    required this.activityName,
    required this.score,
    required this.progress,
    required this.metrics,
    required this.onContinue,
    this.onReview,
    this.customActions,
  }) : super(key: key);

  @override
  State<ActivityResultsDialog> createState() => _ActivityResultsDialogState();
}

class _ActivityResultsDialogState extends State<ActivityResultsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Activity Complete! 🎉',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Ntype82-R',
          color: Colors.white,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Metrics section
            if (widget.metrics.isNotEmpty) ...[
              ..._buildMetricsSection(context),
              SizedBox(height: 24),
            ],
            // Rewards section
            _buildRewardsSection(context),
            SizedBox(height: 16),
            Text(
              'Total Coins: ${widget.progress.totalCoins}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildMetricsSection(BuildContext context) {
    final metricsList = widget.metrics.entries.toList();
    return metricsList.map((entry) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _buildMetricRow(
          context,
          entry.key,
          entry.value,
          _getMetricColor(entry.key),
        ),
      );
    }).toList();
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    dynamic value,
    Color color,
  ) {
    final displayValue = value is num
        ? value.toStringAsFixed(0)
        : value.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.white,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            displayValue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'NType82-R',
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              FaIcon(
                FontAwesomeIcons.coins,
                color: Color(0xFFFFD43B),
                size: 20,
              ),
              SizedBox(height: 8),
              Text(
                '+${_calculateCoinsEarned()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'NType82-R',
                  color: Color(0xFFFFD43B),
                ),
              ),
            ],
          ),
          Column(
            children: [
              FaIcon(FontAwesomeIcons.fire, color: Color(0xFFFF922B), size: 20),
              SizedBox(height: 8),
              Text(
                '${widget.progress.currentStreak}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'NType82-R',
                  color: Color(0xFFFF922B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Review button (if callback provided)
    if (widget.onReview != null) {
      actions.add(
        TextButton(
          onPressed: widget.onReview,
          child: const Text('Review', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Custom actions
    if (widget.customActions != null) {
      actions.addAll(widget.customActions!);
    }

    // Continue button
    actions.add(
      TextButton(
        onPressed: widget.onContinue,
        child: const Text('Continue', style: TextStyle(color: Colors.white)),
      ),
    );

    return actions;
  }

  int _calculateCoinsEarned() {
    // Default base reward is 50, but can vary by activity
    // This uses the score to calculate proportional rewards
    final baseReward = 50;
    return (baseReward * (widget.score / 100)).round();
  }

  Color _getMetricColor(String metricName) {
    final name = metricName.toLowerCase();
    if (name.contains('accuracy')) return Colors.blue;
    if (name.contains('bias')) return Colors.purple;
    if (name.contains('reflection') || name.contains('cognitive'))
      return Colors.orange;
    if (name.contains('justification') || name.contains('quality'))
      return Colors.green;
    if (name.contains('completeness')) return Colors.cyan;
    if (name.contains('structure')) return Colors.indigo;
    return Colors.grey;
  }
}
