import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/progress_service.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/widgets/activity_results_dialog.dart';
import 'package:rheto/screens/contradiction_hunter_review_screen.dart';

class ContradictionHunterScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;

  const ContradictionHunterScreen({
    super.key,
    required this.activity,
    required this.module,
    required this.onComplete,
  });

  @override
  State<ContradictionHunterScreen> createState() =>
      _ContradictionHunterScreenState();
}

class _ContradictionHunterScreenState extends State<ContradictionHunterScreen> {
  // Story data
  late String story;
  late List<Map<String, dynamic>> expectedContradictions;
  late int expectedContradictionCount;
  late Set<int>
  correctSentenceIndices; // Indices of sentences that contain contradictions
  late Future<void> _loadStoryFuture;

  // User interaction state
  late List<String> selectedContradictions;
  late TextEditingController justificationController;
  late List<String> storysentences; // Split story into sentences
  late Set<int>
  selectedSentenceIndices; // Track which sentences are highlighted
  bool isSubmitting = false;
  bool showingStory = true;
  int timeRemaining = 90; // 90 seconds to read story

  @override
  void initState() {
    super.initState();
    justificationController = TextEditingController();
    selectedContradictions = [];
    storysentences = [];
    selectedSentenceIndices = {};
    correctSentenceIndices = {};
    _loadStoryFuture = _loadStoryFromAPI();
  }

  Future<void> _loadStoryFromAPI() async {
    try {
      print(
        'Loading contradiction story from: ${ScoringService.baseUrl}/generate-contradiction-story',
      );

      final difficulty = _getDifficultyLevel(widget.activity.difficulty);

      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/generate-contradiction-story'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'difficulty': difficulty, 'previousStories': []}),
          )
          .timeout(const Duration(seconds: 120));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');

        setState(() {
          story = data['story'] as String;
          // Split story into sentences for tap-to-highlight
          storysentences = _splitIntoSentences(story);
          expectedContradictions = (data['contradictions'] as List)
              .map(
                (contradiction) =>
                    Map<String, dynamic>.from(contradiction as Map),
              )
              .toList();
          expectedContradictionCount =
              data['expectedContradictionCount'] as int;

          // Identify which sentences contain contradictions
          _identifyCorrectSentenceIndices();
        });
        print(
          'Successfully loaded story with $expectedContradictionCount contradictions',
        );

        // Start timer for story reading
        _startStoryTimer();
      } else {
        print('API returned status ${response.statusCode}, using default');
        _setDefaultStory();
      }
    } catch (e) {
      print('❌ ERROR loading story: $e');
      print('Stack trace: ${StackTrace.current}');
      print('⚠️ FALLING BACK TO DEFAULT STORY');
      _setDefaultStory();
    }
  }

  List<String> _splitIntoSentences(String text) {
    // Split by periods, question marks, and exclamation marks
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.where((s) => s.trim().isNotEmpty).toList();
  }

  void _setDefaultStory() {
    setState(() {
      story =
          'Sarah bought a new car on Monday. She drove it to work every day that week. On Friday, she mentioned to her colleague that she had owned the car for three months. Her colleague was surprised because Sarah had just told her on Tuesday that she was considering buying a car. Sarah explained that she had been saving money for the purchase for years, but she only decided to buy it last week. She loves her new car and plans to drive it to the mountains this weekend, which is only 50 miles away. However, she also mentioned that the mountain trip would take at least 8 hours of driving.';
      storysentences = _splitIntoSentences(story);
      expectedContradictions = [
        {
          'type': 'temporal',
          'description':
              'Sarah says she bought the car on Monday but also says she owned it for three months',
        },
        {
          'type': 'motivation_inconsistency',
          'description':
              'She says she decided to buy it last week but also says she had been saving for years',
        },
        {
          'type': 'logical_impossibility',
          'description':
              'A 50-mile trip cannot take 8 hours of driving (that would be ~6 mph)',
        },
      ];
      expectedContradictionCount = 3;
      _identifyCorrectSentenceIndices();
    });
  }

  void _identifyCorrectSentenceIndices() {
    correctSentenceIndices = <int>{};

    // For each expected contradiction, find which sentence indices it corresponds to
    for (final contradiction in expectedContradictions) {
      final description = (contradiction['description'] as String)
          .toLowerCase();

      // Find sentences that contain key words from the contradiction
      for (int i = 0; i < storysentences.length; i++) {
        final sentence = storysentences[i].toLowerCase();
        if (_sentenceRelatedToContradiction(sentence, description)) {
          correctSentenceIndices.add(i);
        }
      }
    }

    print('Identified correct sentence indices: $correctSentenceIndices');
  }

  bool _sentenceRelatedToContradiction(
    String sentence,
    String contradictionDescription,
  ) {
    // Extract key entities/numbers from the contradiction description
    final keyWords = contradictionDescription.split(RegExp(r'[,.\s]+'));

    // Count how many key words appear in the sentence
    int matchCount = 0;
    for (final word in keyWords) {
      if (word.length > 3 && sentence.contains(word)) {
        matchCount++;
      }
    }

    // If multiple key words match, this sentence is likely part of the contradiction
    return matchCount >= 2;
  }

  void _startStoryTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && showingStory) {
        setState(() {
          timeRemaining--;
          if (timeRemaining <= 0) {
            showingStory = false;
          }
        });
        if (timeRemaining > 0) {
          _startStoryTimer();
        }
      }
    });
  }

  String _getDifficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'easy';
      case 'hard':
        return 'hard';
      default:
        return 'medium';
    }
  }

  @override
  void dispose() {
    justificationController.dispose();
    super.dispose();
  }

  Future<void> _submitActivity() async {
    if (selectedContradictions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one contradiction'),
        ),
      );
      return;
    }

    if (justificationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a justification for your selections'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Call backend to score the contradictions
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/score-contradictions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'story': story,
              'detectedContradictions': selectedContradictions,
              'justification': justificationController.text,
              'expectedContradictions': expectedContradictions
                  .map((c) => '${c['type']}: ${c['description']}')
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Scoring response status: ${response.statusCode}');
      print('Scoring response body: ${response.body}');

      if (response.statusCode == 200) {
        final scores = jsonDecode(response.body);

        print('✅ Parsed scores: $scores');
        print(
          '   - accuracy_rate: ${scores['accuracy_rate']} (type: ${scores['accuracy_rate'].runtimeType})',
        );
        print(
          '   - bias_detection_rate: ${scores['bias_detection_rate']} (type: ${scores['bias_detection_rate'].runtimeType})',
        );
        print(
          '   - cognitive_reflection: ${scores['cognitive_reflection']} (type: ${scores['cognitive_reflection'].runtimeType})',
        );
        print(
          '   - justification_quality: ${scores['justification_quality']} (type: ${scores['justification_quality'].runtimeType})',
        );

        final totalScore = (scores['total'] as num).toDouble();

        // Record activity completion
        final metricsToSave = {
          'selectedContradictions': selectedContradictions.length,
          'expectedContradictions': expectedContradictionCount,
          'accuracyRate': scores['accuracy_rate'],
          'biasDetectionRate': scores['bias_detection_rate'],
          'cognitiveReflection': scores['cognitive_reflection'],
          'justificationQuality': scores['justification_quality'],
          'justification': justificationController.text,
        };

        print('📊 Metrics being saved: $metricsToSave');

        final progress = await ProgressService.completeActivity(
          activityId: widget.activity.id,
          score: totalScore.clamp(0, 100),
          moduleType: _getModuleTypeKey(widget.module.type),
          metrics: metricsToSave,
        );

        print(
          '✅ Activity saved. Progress: coins=${progress.totalCoins}, streak=${progress.currentStreak}',
        );
        print(
          '   Last activity metrics: ${progress.completedActivities.last.metrics}',
        );

        if (mounted) {
          _showCompletionDialog(totalScore, progress, scores);
        }
      } else {
        throw Exception('Failed to score contradictions');
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

  void _showCompletionDialog(
    double score,
    UserProgress progress,
    Map<String, dynamic> scores,
  ) {
    // Convert scores to display format with labels
    final metricsDisplay = {
      'Accuracy': scores['accuracy_rate'],
      'Bias Detection': scores['bias_detection_rate'],
      'Cognitive Reflection': scores['cognitive_reflection'],
      'Justification Quality': scores['justification_quality'],
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContradictionHunterReviewScreen(
                story: story,
                storysentences: storysentences,
                userSelectedIndices: selectedSentenceIndices,
                correctSentenceIndices: correctSentenceIndices,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTappableSentences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(storysentences.length, (index) {
        final sentence = storysentences[index];
        final isSelected = selectedSentenceIndices.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selectedSentenceIndices.contains(index)) {
                selectedSentenceIndices.remove(index);
                selectedContradictions.removeWhere((c) => c == sentence);
              } else {
                selectedSentenceIndices.add(index);
                selectedContradictions.add(sentence);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(0xFF74C0FC).withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: RichText(
              text: TextSpan(
                text: sentence + (index < storysentences.length - 1 ? ' ' : ''),
                style: TextStyle(
                  fontFamily: 'Lettera',
                  fontSize: 16,
                  height: 1.8,
                  color: isSelected ? Color(0xFF74C0FC) : Colors.grey[200],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
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
        title: const Text('Contradiction Hunter'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.reply),
          onPressed: () => Navigator.pop(context),
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
      body: FutureBuilder<void>(
        future: _loadStoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading story: ${snapshot.error}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions - Only show while timer is running
                if (showingStory)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFF74C0FC).withOpacity(0.08),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.lightbulb,
                                  color: Color(0xFF74C0FC),
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'How to Play',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'Ntype82-R',
                                        color: Color(0xFF74C0FC),
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '1. Read the story carefully (you have 90 seconds)\n2. Identify all contradictions you find\n3. Tap sentences to highlight them as contradictions\n4. Write a justification explaining why they are contradictions',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'Lettera',
                                    color: Colors.grey[300],
                                    height: 1.6,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                SizedBox(height: 24),

                // Story Section
                if (showingStory)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Read the Story',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontFamily: 'Ntype82-R'),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: timeRemaining > 30
                                      ? Color(0xFF63E6BE).withOpacity(0.2)
                                      : Color(0xFFFF922B).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⏱ ${timeRemaining}s',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontFamily: 'NType82-R',
                                        color: timeRemaining > 30
                                            ? Color(0xFF63E6BE)
                                            : Color(0xFFFF922B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showingStory = false;
                                    timeRemaining = 0;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF74C0FC),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  'Skip',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontFamily: 'NType82-R',
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[900],
                        ),
                        child: _buildTappableSentences(),
                      ),
                      SizedBox(height: 24),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identify Contradictions',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Select all the contradictions you found in the story:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Contradiction selection area - Tappable sentences
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[900],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tap sentences to highlight them as contradictions:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'Lettera',
                                    color: Colors.grey[400],
                                  ),
                            ),
                            SizedBox(height: 12),
                            _buildTappableSentences(),
                            SizedBox(height: 12),
                            Text(
                              '${selectedContradictions.length} sentence(s) selected',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'Lettera',
                                    color: Color(0xFF74C0FC),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Justification section
                      Text(
                        'Justification',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Explain why these are contradictions and how they conflict with each other:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: justificationController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              'Write your explanation here... (Be thorough and logical)',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'Lettera',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF74C0FC)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontFamily: 'Lettera',
                        ),
                      ),
                      SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF74C0FC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF74C0FC),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.check,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Submit Analysis',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontFamily: 'Ntype82-R',
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
