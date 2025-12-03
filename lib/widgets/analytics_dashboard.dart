import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  String _selectedDomain = 'All Domains';
  int _selectedDays = 7;
  bool _isLoading = true;
  List<Map<String, dynamic>> _snapshots = [];

  final List<String> _domains = [
    'All Domains',
    'Critical Thinking',
    'Memory',
    'Creativity',
  ];

  // Colors for each metric
  final Map<String, Color> _metricColors = {
    // Critical Thinking
    'accuracy': const Color(0xFF74C0FC),
    'bias_detection': const Color(0xFF63E6BE),
    'reflection': const Color(0xFFFFD43B),
    'justification': const Color(0xFFFF922B),
    // Memory
    'recall_accuracy': const Color(0xFF74C0FC),
    'recall_latency': const Color(0xFF63E6BE),
    'retention_curve': const Color(0xFFFFD43B),
    'item_mastery': const Color(0xFFFF922B),
    // Creativity
    'fluency': const Color(0xFF74C0FC),
    'flexibility': const Color(0xFF63E6BE),
    'originality': const Color(0xFFFFD43B),
    'refinement': const Color(0xFFFF922B),
    // Domain scores
    'critical_thinking': const Color(0xFF74C0FC),
    'memory': const Color(0xFF63E6BE),
    'creativity': const Color(0xFFFFD43B),
    'overall': const Color(0xFFFF922B),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // All metrics stored locally - no remote snapshots
    setState(() {
      _snapshots = [];
      _isLoading = false;
    });
  }

  // Group snapshots by day
  Map<String, Map<String, double>> _groupByDay() {
    final Map<String, Map<String, double>> grouped = {};

    for (final snapshot in _snapshots) {
      final date = DateTime.parse(snapshot['captured_at'] as String);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final metricName = snapshot['metric_name'] as String;
      final value = (snapshot['value'] as num).toDouble();

      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = {};
      }
      grouped[dayKey]![metricName] = value;
    }

    return grouped;
  }

  // Calculate domain scores for each day
  Map<String, Map<String, double>> _calculateDomainScores() {
    final grouped = _groupByDay();
    final Map<String, Map<String, double>> domainScores = {};

    for (final entry in grouped.entries) {
      final dayKey = entry.key;
      final metrics = entry.value;

      domainScores[dayKey] = {};

      // Critical Thinking: (accuracy * 0.40) + (bias_detection * 0.20) + (reflection * 0.20) + (justification * 0.20)
      final accuracy = metrics['accuracy'] ?? 0;
      final biasDetection = metrics['bias_detection'] ?? 0;
      final reflection = metrics['reflection'] ?? 0;
      final justification = metrics['justification'] ?? 0;
      domainScores[dayKey]!['critical_thinking'] =
          (accuracy * 0.40) +
          (biasDetection * 0.20) +
          (reflection * 0.20) +
          (justification * 0.20);

      // Memory: recall_accuracy * retention_curve * (1 / sqrt(recall_latency)) * item_mastery
      final recallAccuracy = metrics['recall_accuracy'] ?? 0;
      final recallLatency = metrics['recall_latency'] ?? 1;
      final retentionCurve = metrics['retention_curve'] ?? 0;
      final itemMastery = metrics['item_mastery'] ?? 0;
      final memoryScore = recallLatency > 0
          ? recallAccuracy *
                retentionCurve *
                (1 / sqrt(recallLatency)) *
                itemMastery
          : 0.0;
      domainScores[dayKey]!['memory'] = memoryScore.clamp(0, 10);

      // Creativity: (fluency * 0.30) + (flexibility * 0.25) + (originality * 0.25) + (refinement * 0.20)
      final fluency = metrics['fluency'] ?? 0;
      final flexibility = metrics['flexibility'] ?? 0;
      final originality = metrics['originality'] ?? 0;
      final refinement = metrics['refinement'] ?? 0;
      domainScores[dayKey]!['creativity'] =
          (fluency * 0.30) +
          (flexibility * 0.25) +
          (originality * 0.25) +
          (refinement * 0.20);

      // Overall: Average of the three domain scores
      final ct = domainScores[dayKey]!['critical_thinking'] ?? 0;
      final mem = domainScores[dayKey]!['memory'] ?? 0;
      final cre = domainScores[dayKey]!['creativity'] ?? 0;
      domainScores[dayKey]!['overall'] = (ct + mem + cre) / 3;
    }

    return domainScores;
  }

  List<LineChartBarData> _buildChartData() {
    final grouped = _groupByDay();
    final domainScores = _calculateDomainScores();

    // Sort days chronologically
    final sortedDays = grouped.keys.toList()..sort();

    if (sortedDays.isEmpty) return [];

    List<LineChartBarData> lines = [];

    if (_selectedDomain == 'All Domains') {
      // Show overall score line
      final spots = <FlSpot>[];
      for (int i = 0; i < sortedDays.length; i++) {
        final day = sortedDays[i];
        final score = domainScores[day]?['overall'] ?? 0;
        spots.add(FlSpot(i.toDouble(), score));
      }
      lines.add(_createLine(spots, _metricColors['overall']!));
    } else if (_selectedDomain == 'Critical Thinking') {
      // Show individual CT metrics
      final metrics = [
        'accuracy',
        'bias_detection',
        'reflection',
        'justification',
      ];
      for (final metric in metrics) {
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final value = grouped[day]?[metric] ?? 0;
          spots.add(FlSpot(i.toDouble(), value));
        }
        lines.add(_createLine(spots, _metricColors[metric]!));
      }
    } else if (_selectedDomain == 'Memory') {
      // Show individual Memory metrics
      final metrics = [
        'recall_accuracy',
        'recall_latency',
        'retention_curve',
        'item_mastery',
      ];
      for (final metric in metrics) {
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final value = grouped[day]?[metric] ?? 0;
          spots.add(FlSpot(i.toDouble(), value));
        }
        lines.add(_createLine(spots, _metricColors[metric]!));
      }
    } else if (_selectedDomain == 'Creativity') {
      // Show individual Creativity metrics
      final metrics = ['fluency', 'flexibility', 'originality', 'refinement'];
      for (final metric in metrics) {
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final value = grouped[day]?[metric] ?? 0;
          spots.add(FlSpot(i.toDouble(), value));
        }
        lines.add(_createLine(spots, _metricColors[metric]!));
      }
    }

    return lines;
  }

  LineChartBarData _createLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  List<String> _getSortedDays() {
    return _groupByDay().keys.toList()..sort();
  }

  Widget _buildLegend() {
    List<Widget> legendItems = [];

    if (_selectedDomain == 'All Domains') {
      legendItems.add(
        _buildLegendItem('Overall Score', _metricColors['overall']!),
      );
    } else if (_selectedDomain == 'Critical Thinking') {
      legendItems.add(_buildLegendItem('Accuracy', _metricColors['accuracy']!));
      legendItems.add(
        _buildLegendItem('Bias Detection', _metricColors['bias_detection']!),
      );
      legendItems.add(
        _buildLegendItem('Reflection', _metricColors['reflection']!),
      );
      legendItems.add(
        _buildLegendItem('Justification', _metricColors['justification']!),
      );
    } else if (_selectedDomain == 'Memory') {
      legendItems.add(
        _buildLegendItem('Recall Accuracy', _metricColors['recall_accuracy']!),
      );
      legendItems.add(
        _buildLegendItem('Recall Latency', _metricColors['recall_latency']!),
      );
      legendItems.add(
        _buildLegendItem('Retention Curve', _metricColors['retention_curve']!),
      );
      legendItems.add(
        _buildLegendItem('Item Mastery', _metricColors['item_mastery']!),
      );
    } else if (_selectedDomain == 'Creativity') {
      legendItems.add(_buildLegendItem('Fluency', _metricColors['fluency']!));
      legendItems.add(
        _buildLegendItem('Flexibility', _metricColors['flexibility']!),
      );
      legendItems.add(
        _buildLegendItem('Originality', _metricColors['originality']!),
      );
      legendItems.add(
        _buildLegendItem('Refinement', _metricColors['refinement']!),
      );
    }

    return Wrap(spacing: 16, runSpacing: 8, children: legendItems);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Lettera',
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedDays = _getSortedDays();
    final chartData = _buildChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Analytics',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        const SizedBox(height: 16),

        // Domain selector and date range filter
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDomain,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF181c1f),
                    style: const TextStyle(
                      fontFamily: 'Lettera',
                      color: Colors.white,
                    ),
                    items: _domains.map((domain) {
                      return DropdownMenuItem(
                        value: domain,
                        child: Text(
                          domain,
                          style: const TextStyle(fontFamily: 'Lettera'),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDomain = value);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDays,
                  dropdownColor: const Color(0xFF181c1f),
                  style: const TextStyle(
                    fontFamily: 'Lettera',
                    color: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 7,
                      child: Text(
                        '7 days',
                        style: TextStyle(fontFamily: 'Lettera'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text(
                        '30 days',
                        style: TextStyle(fontFamily: 'Lettera'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDays = value);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
        const SizedBox(height: 16),

        // Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : sortedDays.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(
                      fontFamily: 'Lettera',
                      color: Colors.grey[500],
                    ),
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey[800], strokeWidth: 1);
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontFamily: 'Lettera',
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= sortedDays.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              'Day ${index + 1}',
                              style: TextStyle(
                                fontFamily: 'Lettera',
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: sortedDays.length - 1 > 0
                        ? (sortedDays.length - 1).toDouble()
                        : 1,
                    minY: 0,
                    maxY: 10,
                    lineBarsData: chartData,
                  ),
                ),
        ),
      ],
    );
  }
}
