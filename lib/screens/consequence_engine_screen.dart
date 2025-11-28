import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/services/progress_service.dart';
import 'package:rheto/widgets/activity_results_dialog.dart';

class ConsequenceEngineScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;

  const ConsequenceEngineScreen({
    super.key,
    required this.activity,
    required this.module,
    required this.onComplete,
  });

  @override
  State<ConsequenceEngineScreen> createState() =>
      _ConsequenceEngineScreenState();
}

class _ConsequenceEngineScreenState extends State<ConsequenceEngineScreen> {
  late String currentPremise;
  late List<String> previousPremises;
  late Future<void> _loadPremiseFuture;

  late List<List<String>> completedChains;
  late List<String> currentChain;
  late List<Map<String, dynamic>> chainScores;

  int currentLevel = 0;
  late TextEditingController consequenceController;
  bool isSubmitting = false;
  bool showingResults = false;
  Map<String, dynamic>? finalScores;
  double? finalScore;

  bool isInRemixMode = false;
  int? remixFromLevel;

  @override
  void initState() {
    super.initState();
    consequenceController = TextEditingController();
    previousPremises = [];
    completedChains = [];
    currentChain = ['', '', '', ''];
    chainScores = [];
    _loadPremiseFuture = _loadNewPremise();
  }

  @override
  void dispose() {
    consequenceController.dispose();
    super.dispose();
  }

  Future<void> _loadNewPremise() async {
    try {
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/generate-premise'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'previousPremises': previousPremises}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentPremise = data['premise'] as String;
          previousPremises.add(currentPremise);
        });
      } else {
        _setDefaultPremise();
      }
    } catch (e) {
      _setDefaultPremise();
    }
  }

  void _setDefaultPremise() {
    setState(() {
      currentPremise = 'Gravity now only works on Tuesdays';
      previousPremises.add(currentPremise);
    });
  }

  Future<void> _submitChain() async {
    if (currentChain.any((c) => c.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all 4 levels')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/score-consequences'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'premise': currentPremise,
              'chain': currentChain,
              'chainIndex': completedChains.length + 1,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final scores = jsonDecode(response.body);
        setState(() {
          completedChains.add(List<String>.from(currentChain));
          chainScores.add(scores);
          currentChain = ['', '', '', ''];
          currentLevel = 0;
          consequenceController.clear();
        });

        // Check if user completed 2 chains
        if (completedChains.length >= 2) {
          _calculateFinalScores();
        } else {
          // Offer to continue or remix
          _showChainCompletedDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error scoring chain. Try again.')),
        );
      }
    } catch (e) {
      print('Error submitting chain: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _calculateFinalScores() async {
    // Average scores across all chains
    double avgFluency = 0;
    double avgFlexibility = 0;
    double avgOriginality = 0;
    double avgRefinement = 0;

    for (final score in chainScores) {
      avgFluency += (score['fluency'] as num).toDouble();
      avgFlexibility += (score['flexibility'] as num).toDouble();
      avgOriginality += (score['originality'] as num).toDouble();
      avgRefinement += (score['refinement_gain'] as num).toDouble();
    }

    avgFluency /= chainScores.length;
    avgFlexibility /= chainScores.length;
    avgOriginality /= chainScores.length;
    avgRefinement /= chainScores.length;

    // Calculate final score (0-100)
    final totalPoints =
        avgFluency + avgFlexibility + avgOriginality + avgRefinement;
    final score = (totalPoints / 20) * 100;

    // Scale scores from 0-5 to 0-10 for consistency with other activities
    final scaledFluency = avgFluency * 2;
    final scaledFlexibility = avgFlexibility * 2;
    final scaledOriginality = avgOriginality * 2;
    final scaledRefinement = avgRefinement * 2;

    // Record activity completion with ProgressService
    try {
      final progress = await ProgressService.completeActivity(
        activityId: widget.activity.id,
        score: score,
        moduleType: _getModuleTypeKey(widget.module.type),
        metrics: {
          'fluency': scaledFluency,
          'flexibility': scaledFlexibility,
          'originality': scaledOriginality,
          'refinement_gain': scaledRefinement,
          'chains_completed': completedChains.length,
        },
      );

      setState(() {
        finalScores = {
          'Fluency': avgFluency.toStringAsFixed(1),
          'Flexibility': avgFlexibility.toStringAsFixed(1),
          'Originality': avgOriginality.toStringAsFixed(1),
          'Refinement Gain': avgRefinement.toStringAsFixed(1),
        };
        finalScore = score;
        showingResults = true;
      });

      _showCompletionDialog(progress);
    } catch (e) {
      print('Error recording activity: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getModuleTypeKey(ModuleType type) {
    switch (type) {
      case ModuleType.criticalThinking:
        return 'criticalThinking';
      case ModuleType.memory:
        return 'memory';
      case ModuleType.creativity:
        return 'creativity';
    }
  }

  void _showCompletionDialog(UserProgress progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivityResultsDialog(
        activityName: widget.activity.name,
        score: finalScore!,
        progress: progress,
        metrics: finalScores!,
        onContinue: () {
          Navigator.pop(context);
          widget.onComplete();
        },
      ),
    );
  }

  void _showChainCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Chain Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chain ${completedChains.length} Score:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildScoreDisplay(chainScores.last),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.withOpacity(0.1),
              ),
              child: Text(
                '⚠️ You won\'t get your points if you don\'t complete 2 chains before finishing!',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ),
            const SizedBox(height: 20),
            Text('You can:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            const Text('• Start a new chain with a new premise'),
            const Text('• Remix from any level of your previous chain'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewChain();
            },
            child: const Text('New Chain'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRemixOptions();
            },
            child: const Text('Remix'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(Map<String, dynamic> scores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreRow('Fluency', scores['fluency']),
        _buildScoreRow('Flexibility', scores['flexibility']),
        _buildScoreRow('Originality', scores['originality']),
        _buildScoreRow('Refinement Gain', scores['refinement_gain']),
      ],
    );
  }

  Widget _buildScoreRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value}/5',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF74C0FC),
            ),
          ),
        ],
      ),
    );
  }

  void _startNewChain() {
    setState(() {
      currentChain = ['', '', '', ''];
      currentLevel = 0;
      consequenceController.clear();
      isInRemixMode = false;
      remixFromLevel = null;
    });
  }

  void _showRemixOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Choose a Level to Remix From'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRemixOption(0, 'Personal', completedChains.last[0]),
            _buildRemixOption(1, 'Social', completedChains.last[1]),
            _buildRemixOption(2, 'Economic', completedChains.last[2]),
            _buildRemixOption(3, 'Ecological', completedChains.last[3]),
          ],
        ),
      ),
    );
  }

  Widget _buildRemixOption(int level, String label, String consequence) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _startRemixFromLevel(level);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[600]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[800],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF74C0FC),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              consequence,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _startRemixFromLevel(int level) {
    setState(() {
      isInRemixMode = true;
      remixFromLevel = level;
      currentLevel = level;
      currentChain = List<String>.from(completedChains.last);
      // Clear levels after the remix point
      for (int i = level + 1; i < 4; i++) {
        currentChain[i] = '';
      }
      consequenceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showingResults) {
      return const SizedBox.expand(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<void>(
      future: _loadPremiseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Consequence Engine')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Consequence Engine'),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premise Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF74C0FC),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF74C0FC).withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premise',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF74C0FC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentPremise,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Ntype82-R',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Chain Progress
                _buildChainProgress(),
                const SizedBox(height: 24),

                // Current Level Instructions
                _buildLevelInstructions(),
                const SizedBox(height: 16),

                // Consequence Input
                _buildConsequenceInput(),
                const SizedBox(height: 24),

                // Navigation Buttons
                _buildNavigationButtons(),
                const SizedBox(height: 32),

                // Completed Chains Summary
                if (completedChains.isNotEmpty) _buildChainsSummary(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChainProgress() {
    const domains = ['Personal', 'Social', 'Economic', 'Ecological'];
    const colors = [
      Color(0xFF63E6BE),
      Color(0xFF74C0FC),
      Color(0xFFFFD43B),
      Color(0xFFFF922B),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chain ${completedChains.length + 1} Progress',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: index <= currentLevel
                          ? colors[index]
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    domains[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: index <= currentLevel
                          ? colors[index]
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelInstructions() {
    const instructions = [
      'Personal: How does this affect an individual person?',
      'Social: How does this change society or group dynamics?',
      'Economic: What are the financial or market implications?',
      'Ecological: How does this impact nature or the environment?',
    ];

    const tips = [
      'Tip: Don\'t just say "I float." Say "I schedule all heavy lifting for Tuesdays."',
      'Tip: Show how people organize around this. Create new professions or conflicts.',
      'Tip: Think about industries, jobs, and wealth shifts. What booms? What crashes?',
      'Tip: Consider predator-prey dynamics, migration, evolution, or ecosystem balance.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instructions[currentLevel],
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tips[currentLevel],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsequenceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Consequence (50-150 characters)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: consequenceController,
          maxLines: 3,
          maxLength: 150,
          onChanged: (value) {
            setState(() {
              currentChain[currentLevel] = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Write your consequence here...',
            hintStyle: TextStyle(color: Colors.grey[600]),
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
              borderSide: const BorderSide(color: Color(0xFF74C0FC), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[900],
            counterStyle: TextStyle(color: Colors.grey[500]),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${consequenceController.text.length}/150',
          style: TextStyle(
            color: consequenceController.text.length < 50
                ? Colors.orange
                : Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (currentLevel > 0)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  currentLevel--;
                  consequenceController.text = currentChain[currentLevel];
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (currentLevel > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSubmitting
                ? null
                : () {
                    if (consequenceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please write a consequence'),
                        ),
                      );
                      return;
                    }
                    if (consequenceController.text.length < 50) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimum 50 characters required'),
                        ),
                      );
                      return;
                    }

                    if (currentLevel < 3) {
                      setState(() {
                        currentLevel++;
                        consequenceController.text = currentChain[currentLevel];
                      });
                    } else {
                      _submitChain();
                    }
                  },
            icon: Icon(currentLevel < 3 ? Icons.arrow_forward : Icons.check),
            label: Text(currentLevel < 3 ? 'Next' : 'Submit Chain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF74C0FC),
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChainsSummary() {
    const domains = ['Personal', 'Social', 'Economic', 'Ecological'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text(
          'Completed Chains',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          completedChains.length,
          (chainIndex) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[900],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chain ${chainIndex + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(chainScores[chainIndex]['total'] as num).toInt()}/100',
                      style: const TextStyle(
                        color: Color(0xFF74C0FC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  4,
                  (levelIndex) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domains[levelIndex],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          completedChains[chainIndex][levelIndex],
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
