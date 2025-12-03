import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rheto/services/metrics_database.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  String _selectedDomain = 'All Domains';
  int _selectedDays = 7;
  bool _isLoading = true;
  List<DailyMetrics> _dailyMetrics = [];

  final List<String> _domains = [
    'All Domains',
    'Critical Thinking',
    'Memory',
    'Creativity',
  ];

  // Colors for each metric
  final Map<String, Color> _metricColors = {
    // Critical Thinking
    'accuracy_rate': const Color(0xFF74C0FC),
    'bias_detection_rate': const Color(0xFF63E6BE),
    'cognitive_reflection': const Color(0xFFFFD43B),
    'justification_quality': const Color(0xFFFF922B),
    // Memory
    'recall_accuracy': const Color(0xFF74C0FC),
    'recall_latency': const Color(0xFF63E6BE),
    'retention_curve': const Color(0xFFFFD43B),
    'item_mastery': const Color(0xFFFF922B),
    // Creativity
    'fluency': const Color(0xFF74C0FC),
    'flexibility': const Color(0xFF63E6BE),
    'originality': const Color(0xFFFFD43B),
    'refinement_gain': const Color(0xFFFF922B),
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

    try {
      // Load daily aggregates from SQLite database
      final dailyData = await MetricsDatabase.getDailyAggregates(
        startTime: DateTime.now().subtract(Duration(days: _selectedDays)),
        endTime: DateTime.now(),
      );

      setState(() {
        _dailyMetrics = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      setState(() {
        _dailyMetrics = [];
        _isLoading = false;
      });
    }
  }

  List<LineChartBarData> _buildChartData() {
    if (_dailyMetrics.isEmpty) return [];

    List<LineChartBarData> lines = [];

    if (_selectedDomain == 'All Domains') {
      // Show overall score line (average of 3 domain scores)
      final spots = <FlSpot>[];
      for (int i = 0; i < _dailyMetrics.length; i++) {
        final dm = _dailyMetrics[i];
        final overall =
            (dm.criticalThinkingScore + dm.memoryScore + dm.creativityScore) /
            3;
        spots.add(FlSpot(i.toDouble(), overall));
      }
      lines.add(_createLine(spots, _metricColors['overall']!));
    } else if (_selectedDomain == 'Critical Thinking') {
      // Show individual CT metrics
      final metrics = [
        'accuracy_rate',
        'bias_detection_rate',
        'cognitive_reflection',
        'justification_quality',
      ];
      for (final metric in metrics) {
        final spots = <FlSpot>[];
        for (int i = 0; i < _dailyMetrics.length; i++) {
          final value = _dailyMetrics[i].getMetric(metric);
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
        for (int i = 0; i < _dailyMetrics.length; i++) {
          final value = _dailyMetrics[i].getMetric(metric);
          spots.add(FlSpot(i.toDouble(), value));
        }
        lines.add(_createLine(spots, _metricColors[metric]!));
      }
    } else if (_selectedDomain == 'Creativity') {
      // Show individual Creativity metrics
      final metrics = [
        'fluency',
        'flexibility',
        'originality',
        'refinement_gain',
      ];
      for (final metric in metrics) {
        final spots = <FlSpot>[];
        for (int i = 0; i < _dailyMetrics.length; i++) {
          final value = _dailyMetrics[i].getMetric(metric);
          spots.add(FlSpot(i.toDouble(), value));
        }
        lines.add(_createLine(spots, _metricColors[metric]!));
      }
    }

    return lines;
  }

  LineChartBarData _createLine(List<FlSpot> spots, Color color) {
    // Disable curve for single point or two points to avoid visual glitches
    final shouldCurve = spots.length > 2;

    return LineChartBarData(
      spots: spots,
      isCurved: shouldCurve,
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

  Widget _buildLegend() {
    List<Widget> legendItems = [];

    if (_selectedDomain == 'All Domains') {
      legendItems.add(
        _buildLegendItem('Overall Score', _metricColors['overall']!),
      );
    } else if (_selectedDomain == 'Critical Thinking') {
      legendItems.add(
        _buildLegendItem('Accuracy', _metricColors['accuracy_rate']!),
      );
      legendItems.add(
        _buildLegendItem(
          'Bias Detection',
          _metricColors['bias_detection_rate']!,
        ),
      );
      legendItems.add(
        _buildLegendItem('Reflection', _metricColors['cognitive_reflection']!),
      );
      legendItems.add(
        _buildLegendItem(
          'Justification',
          _metricColors['justification_quality']!,
        ),
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
        _buildLegendItem('Refinement', _metricColors['refinement_gain']!),
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
    final chartData = _buildChartData();
    final dayCount = _dailyMetrics.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              : dayCount == 0
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
                      horizontalInterval: 20, // 0, 20, 40, 60, 80, 100
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey[800], strokeWidth: 1);
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 20, // Show 0, 20, 40, 60, 80, 100
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
                          interval: 1, // Only show labels at integer positions
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            // Only show label if value is exactly an integer and within bounds
                            if (value != index.toDouble() ||
                                index < 0 ||
                                index >= dayCount) {
                              return const SizedBox.shrink();
                            }
                            // Show date label
                            final date = _dailyMetrics[index].date;
                            return Text(
                              '${date.month}/${date.day}',
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
                    // For single data point, center it by using -0.5 to 0.5 range
                    minX: dayCount == 1 ? -0.5 : 0,
                    maxX: dayCount == 1 ? 0.5 : (dayCount - 1).toDouble(),
                    minY: 0,
                    maxY: 100, // Metrics are on 0-100 scale
                    lineBarsData: chartData,
                    clipData: FlClipData.all(),
                    // Format tooltip to show clean numbers
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              spot.y.toStringAsFixed(1),
                              TextStyle(
                                color: spot.bar.color,
                                fontFamily: 'Lettera',
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
