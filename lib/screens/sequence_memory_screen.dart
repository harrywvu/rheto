import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/hard-coded-lists/randomWords.dart';
import 'dart:convert';
import 'dart:math';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rheto/widgets/activity_results_dialog.dart';

enum ActivityPhase { exposure, reordering, feedback }

class SequenceMemoryScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;

  const SequenceMemoryScreen({
    super.key,
    required this.activity,
    required this.module,
    required this.onComplete,
  });

  @override
  State<SequenceMemoryScreen> createState() => _SequenceMemoryScreenState();
}

class _SequenceMemoryScreenState extends State<SequenceMemoryScreen> {
  // Story and events
  late List<StoryEvent> events;
  late List<StoryEvent> correctSequence;
  late String storyContext;

  // Activity phases
  late ActivityPhase currentPhase;
  late List<StoryEvent> userAttempt;
  late int exposureTimeRemaining;
  late bool exposureComplete;

  // Timing
  late DateTime startTime;
  late DateTime reorderingStartTime;
  bool isSubmitting = false;

  // Retention tracking
  late int attemptCount;
  late double retentionScore;

  // Review tracking
  late int correctCount;
  bool isInReview = false;

  @override
  void initState() {
    super.initState();
    _initializeActivity();
  }

  void _initializeActivity() {
    startTime = DateTime.now();
    _generateStory();
    _loadRetentionData();
    currentPhase = ActivityPhase.exposure;
    exposureTimeRemaining = 15; // 15 seconds to read the story
    exposureComplete = false;
    userAttempt = [];
    _startExposureTimer();
  }

  void _startExposureTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && currentPhase == ActivityPhase.exposure) {
        setState(() {
          exposureTimeRemaining--;
          if (exposureTimeRemaining <= 0) {
            _transitionToReordering();
          }
        });
        _startExposureTimer();
      }
    });
  }

  void _transitionToReordering() {
    setState(() {
      currentPhase = ActivityPhase.reordering;
      reorderingStartTime = DateTime.now();
      // Shuffle events for reordering phase with multiple passes
      events = List.from(correctSequence);
      _robustShuffle(events);
    });
  }

  void _robustShuffle(List<StoryEvent> list) {
    // Fisher-Yates shuffle with multiple passes to ensure randomization
    final random = Random();
    for (int pass = 0; pass < 3; pass++) {
      for (int i = list.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = list[i];
        list[i] = list[j];
        list[j] = temp;
      }
    }
  }

  void _generateStory() {
    // Generate a simple story with 6-8 events
    final stories = SEQUENCE_MEMORY_STORIES;

    final selectedStory = stories[DateTime.now().millisecond % stories.length];
    storyContext = selectedStory['context'] as String;
    correctSequence = (selectedStory['events'] as List<String>)
        .map((e) => StoryEvent(text: e))
        .toList();

    // Shuffle the events for the user to reorder with robust randomization
    events = List.from(correctSequence);
    _robustShuffle(events);
  }

  Future<void> _loadRetentionData() async {
    final prefs = await SharedPreferences.getInstance();
    final activityKey = 'seq_memory_${widget.activity.id}';

    // Load previous attempt count
    attemptCount = prefs.getInt('${activityKey}_attempts') ?? 0;

    // Load retention score (average of previous attempts)
    final previousScores = prefs.getStringList('${activityKey}_scores') ?? [];
    if (previousScores.isNotEmpty) {
      final scores = previousScores.map((s) => double.parse(s)).toList();
      retentionScore = scores.reduce((a, b) => a + b) / scores.length;
    } else {
      retentionScore = 0.0;
    }
  }

  void _submitReordering() async {
    // Calculate correct count for later use in review
    correctCount = 0;
    for (int i = 0; i < events.length; i++) {
      if (events[i].text == correctSequence[i].text) {
        correctCount++;
      }
    }

    // Show completion dialog instead of moving to feedback phase
    await _completeActivity();
  }

  Future<void> _completeActivity() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Use the correctCount calculated in _submitReordering
      final recallAccuracy = (correctCount / events.length * 5).clamp(0.0, 5.0);

      // Calculate recall latency (time taken from reordering start, normalized to 0-5 scale)
      final reorderingSeconds = DateTime.now()
          .difference(reorderingStartTime)
          .inSeconds;
      final maxTime = 300; // 5 minutes is considered max time
      final recallLatency = ((maxTime - reorderingSeconds) / maxTime * 5).clamp(
        0.0,
        5.0,
      );

      // Calculate retention curve (improvement over attempts)
      final retentionCurve = _calculateRetentionCurve(recallAccuracy);

      // Item mastery (consistency of correct items)
      final itemMastery = _calculateItemMastery(correctCount);

      // Calculate total score
      final totalScore =
          (((recallAccuracy * 3 +
                      recallLatency * 2 +
                      retentionCurve * 3 +
                      itemMastery * 1) /
                  9 *
                  100)
              .clamp(0.0, 100.0));

      // Save attempt data
      await _saveAttemptData(recallAccuracy, totalScore);

      // Record activity completion
      final progress = await ProgressService.completeActivity(
        activityId: widget.activity.id,
        score: totalScore,
        moduleType: _getModuleTypeKey(widget.module.type),
        metrics: {
          'recallAccuracy': recallAccuracy,
          'recallLatency': recallLatency,
          'retentionCurve': retentionCurve,
          'itemMastery': itemMastery,
          'correctCount': correctCount,
          'totalEvents': events.length,
          'timeElapsed': reorderingSeconds,
        },
      );

      // Show completion dialog
      if (mounted) {
        _showCompletionDialog(totalScore, progress, correctCount);
      }
    } catch (e) {
      print('Error submitting activity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting activity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  double _calculateRetentionCurve(double currentAccuracy) {
    // Retention curve: how well user is retaining over multiple attempts
    // Uses Ebbinghaus forgetting curve concept
    // Returns a value 0-5 based on improvement over attempts
    if (attemptCount == 0) {
      // First attempt: return current accuracy normalized to 0-5
      return (currentAccuracy / 5).clamp(0.0, 5.0);
    }

    // Calculate improvement from previous attempts
    final improvement = currentAccuracy - (retentionScore * 5);
    // Weight improvement by attempt count (diminishing returns)
    final retentionBonus = (improvement * 0.5).clamp(0.0, 5.0);
    // Combine previous retention with new improvement
    final newRetention = ((retentionScore + retentionBonus) / 2).clamp(
      0.0,
      5.0,
    );

    return newRetention;
  }

  double _calculateItemMastery(int correctCount) {
    // Item mastery: consistency of getting the same items correct
    // Simplified: based on how many items are correct
    return (correctCount / events.length * 5).clamp(0, 5).toDouble();
  }

  Future<void> _saveAttemptData(double accuracy, double score) async {
    final prefs = await SharedPreferences.getInstance();
    final activityKey = 'seq_memory_${widget.activity.id}';

    // Increment attempt count
    await prefs.setInt('${activityKey}_attempts', attemptCount + 1);

    // Save score to history
    final previousScores = prefs.getStringList('${activityKey}_scores') ?? [];
    previousScores.add(score.toString());
    await prefs.setStringList('${activityKey}_scores', previousScores);

    // Save last sequence attempt
    final sequenceData = {
      'timestamp': DateTime.now().toIso8601String(),
      'score': score,
      'accuracy': accuracy,
      'sequence': events.map((e) => e.text).toList(),
    };
    await prefs.setString(
      '${activityKey}_last_attempt',
      jsonEncode(sequenceData),
    );
  }

  void _showCompletionDialog(
    double score,
    UserProgress progress,
    int correctCount,
  ) {
    final metricsDisplay = {
      'Correct Events': '$correctCount/${events.length}',
      'Recall Accuracy':
          '${(correctCount / events.length * 100).toStringAsFixed(0)}%',
      'Time Taken': '${DateTime.now().difference(startTime).inSeconds}s',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivityResultsDialog(
        activityName: widget.activity.name,
        score: score,
        progress: progress,
        metrics: metricsDisplay,
        onContinue: () {
          Navigator.pop(context);
          Navigator.pop(context);
          widget.onComplete();
        },
        onReview: () {
          Navigator.pop(context);
          setState(() {
            currentPhase = ActivityPhase.feedback;
            isInReview = true;
          });
        },
      ),
    );
  }

  String _getModuleTypeKey(ModuleType type) {
    switch (type) {
      case ModuleType.criticalThinking:
        return 'criticalThinking';
      case ModuleType.memory:
        return 'memory';
      case ModuleType.creativity:
        return 'creativity';
      case ModuleType.aiLaboratory:
        return 'aiLaboratory';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.reply),
          onPressed: () {
            if (isInReview) {
              // If in review, go back to activity list
              Navigator.pop(context);
              widget.onComplete();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('Quit Activity?'),
                  content: const Text(
                    'Are you sure you want to quit? Your progress will not be saved.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Quit',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story context
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900]?.withOpacity(0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Story Context',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    storyContext,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Content based on phase
            if (currentPhase == ActivityPhase.exposure)
              _buildExposurePhase(context)
            else if (currentPhase == ActivityPhase.reordering)
              _buildReorderingPhase(context)
            else
              _buildFeedbackPhase(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExposurePhase(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning Phase',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
              ),
              SizedBox(height: 8),
              Text(
                'Read the story carefully. You have ${exposureTimeRemaining}s to memorize the sequence of events.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Story Events (in order)',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        SizedBox(height: 12),
        // Show events in correct order with visual cues
        ...List.generate(
          correctSequence.length,
          (index) => _buildCorrectEventTile(index),
        ),
        SizedBox(height: 32),
        // Timer display
        Center(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: exposureTimeRemaining <= 5
                    ? Color(0xFFFF6B6B)
                    : Color(0xFF008000),
                width: 3,
              ),
            ),
            child: Text(
              '${exposureTimeRemaining}s',
              style: TextStyle(
                fontFamily: 'Ntype82-R',
                fontSize: 32,
                color: exposureTimeRemaining <= 5
                    ? Color(0xFFFF6B6B)
                    : Color(0xFF008000),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectEventTile(int index) {
    final colors = [
      Color(0xFF74C0FC),
      Color(0xFFA78BFA),
      Color(0xFF86EFAC),
      Color(0xFFFBBF24),
      Color(0xFFFCA5A5),
      Color(0xFF67E8F9),
      Color(0xFFC084FC),
      Color(0xFF60A5FA),
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors[index % colors.length]),
        borderRadius: BorderRadius.circular(12),
        color: colors[index % colors.length].withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[index % colors.length],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'Ntype82-R',
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              correctSequence[index].text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Ntype82-R',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderingPhase(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reordering Phase',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
              ),
              SizedBox(height: 8),
              Text(
                'Now from memory, drag and drop the cards to arrange them in the correct order.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Reorder Events',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = events.removeAt(oldIndex);
              events.insert(newIndex, item);
            });
          },
          children: List.generate(
            events.length,
            (index) => _buildEventTile(index),
          ),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReordering,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008000),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Submit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeedbackPhase(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Phase',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
              ),
              SizedBox(height: 8),
              Text(
                'You got $correctCount out of ${events.length} events correct!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Your Attempt vs Correct Order',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        SizedBox(height: 12),
        // Show comparison
        ...List.generate(
          events.length,
          (index) => _buildFeedbackComparison(index, correctCount),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008000),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Back to Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeedbackComparison(int index, int correctCount) {
    final isCorrect = events[index].text == correctSequence[index].text;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCorrect ? Color(0xFF86EFAC) : Color(0xFFFCA5A5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isCorrect
            ? Color(0xFF86EFAC).withOpacity(0.1)
            : Color(0xFFFCA5A5).withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect ? Color(0xFF86EFAC) : Color(0xFFFCA5A5),
                ),
                child: Center(
                  child: FaIcon(
                    isCorrect ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position ${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Lettera',
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      events[index].text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Ntype82-R',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Should be:',
                    style: TextStyle(
                      fontFamily: 'Lettera',
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    correctSequence[index].text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Ntype82-R',
                      color: Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventTile(int index) {
    return Container(
      key: ValueKey(index),
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900]?.withOpacity(0.5),
      ),
      child: Row(
        children: [
          // Drag handle
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: FaIcon(
              FontAwesomeIcons.gripVertical,
              color: Colors.grey[600],
              size: 16,
            ),
          ),
          SizedBox(width: 16),

          // Event number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[600]!, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'Ntype82-R',
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),

          // Event text
          Expanded(
            child: Text(
              events[index].text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Ntype82-R',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoryEvent {
  final String text;

  StoryEvent({required this.text});
}
