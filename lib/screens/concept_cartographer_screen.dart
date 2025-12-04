import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:rheto/models/module.dart';
import 'package:rheto/models/graph_models.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/widgets/activity_results_dialog.dart';
import 'package:rheto/widgets/graph_canvas_enhanced.dart';
import 'package:rheto/widgets/ai_review_panel.dart';
import 'package:rheto/services/progress_service.dart';

enum ConceptPhase {
  topicSelection,
  selfAssessment,
  conceptAssembly,
  testModel,
  teachBack,
}

class ConceptPiece {
  final String id;
  final String label;
  final String description;
  int position; // For drag-and-drop ordering

  ConceptPiece({
    required this.id,
    required this.label,
    required this.description,
    required this.position,
  });
}

class ConceptConnection {
  final String fromId;
  final String toId;
  final String label; // "causes", "requires", "contradicts", etc.

  ConceptConnection({
    required this.fromId,
    required this.toId,
    required this.label,
  });
}

class ConceptCartographerScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;

  const ConceptCartographerScreen({
    super.key,
    required this.activity,
    required this.module,
    required this.onComplete,
  });

  @override
  State<ConceptCartographerScreen> createState() =>
      _ConceptCartographerScreenState();
}

class _ConceptCartographerScreenState extends State<ConceptCartographerScreen> {
  // Phase management
  ConceptPhase currentPhase = ConceptPhase.topicSelection;

  // Topic and pieces
  late String currentTopic;
  late String topicDescription;
  late List<ConceptPiece> conceptPieces;
  late List<ConceptConnection> connections;

  // Topic selection
  late TextEditingController topicInputController;
  bool isLoadingTopic = false;

  // Loading states for AI submissions
  bool isSubmittingSelfAssessment = false;
  bool isSubmittingPrediction = false;
  bool isSubmittingTeachBack = false;

  // Self-Assessment Phase
  late TextEditingController priorKnowledgeController;
  Map<String, dynamic>? assessmentFeedback;

  // Concept Assembly Phase
  late List<ConceptPiece> orderedPieces;
  late List<ConceptConnection> userConnections;
  Set<String> confusionFlags = {};
  late GraphModel graphModel;
  late GlobalKey<State<GraphCanvasEnhanced>> graphCanvasKey;

  // Connection building state
  String? selectedFromId;
  String? selectedToId;
  late TextEditingController connectionLabelController;

  // Test Your Model Phase
  late String scenarioQuestion;
  late TextEditingController predictionController;
  Map<String, dynamic>? scenarioFeedback;

  // Teach-Back Phase
  late TextEditingController teachBackController;
  Map<String, dynamic>? teachBackFeedback;

  // Results
  bool showingResults = false;
  Map<String, dynamic>? finalScores;
  double? finalScore;

  @override
  void initState() {
    super.initState();
    topicInputController = TextEditingController();
    priorKnowledgeController = TextEditingController();
    predictionController = TextEditingController();
    teachBackController = TextEditingController();
    connectionLabelController = TextEditingController();
    orderedPieces = [];
    userConnections = [];
    graphModel = GraphModel();
    graphCanvasKey = GlobalKey<State<GraphCanvasEnhanced>>();
  }

  @override
  void dispose() {
    topicInputController.dispose();
    priorKnowledgeController.dispose();
    predictionController.dispose();
    teachBackController.dispose();
    connectionLabelController.dispose();
    super.dispose();
  }

  Future<void> _generateTopicFromInput(String userTopic) async {
    if (userTopic.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a topic')));
      return;
    }

    setState(() => isLoadingTopic = true);

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ScoringService.baseUrl}/generate-custom-concept-topic',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'topic': userTopic.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          setState(() {
            currentTopic = data['topic'] as String;
            topicDescription = data['description'] as String;
            conceptPieces = (data['pieces'] as List)
                .asMap()
                .entries
                .map(
                  (e) => ConceptPiece(
                    id: e.value['id'] as String,
                    label: e.value['label'] as String,
                    description: e.value['description'] as String,
                    position: e.key,
                  ),
                )
                .toList();
            orderedPieces = List.from(conceptPieces);
            connections = (data['connections'] as List? ?? [])
                .map(
                  (c) => ConceptConnection(
                    fromId: c['fromId'] as String,
                    toId: c['toId'] as String,
                    label: c['label'] as String,
                  ),
                )
                .toList();
            currentPhase = ConceptPhase.selfAssessment;
            isLoadingTopic = false;
            _initializeGraph();
          });
        } catch (parseError) {
          setState(() => isLoadingTopic = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing response: $parseError')),
          );
        }
      } else {
        setState(() => isLoadingTopic = false);
        final errorMessage = response.statusCode == 500
            ? 'Server error. Please try a different topic.'
            : 'Error generating topic (${response.statusCode}). Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      setState(() => isLoadingTopic = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _setDefaultTopic() {
    setState(() {
      currentTopic = 'Photosynthesis';
      topicDescription =
          'The process by which plants convert light energy into chemical energy';
      conceptPieces = [
        ConceptPiece(
          id: 'p1',
          label: 'Chlorophyll',
          description: 'Light absorption pigment',
          position: 0,
        ),
        ConceptPiece(
          id: 'p2',
          label: 'Carbon Dioxide',
          description: 'Gas intake from atmosphere',
          position: 1,
        ),
        ConceptPiece(
          id: 'p3',
          label: 'Water Splitting',
          description: 'H2O breakdown in light reactions',
          position: 2,
        ),
        ConceptPiece(
          id: 'p4',
          label: 'Glucose Production',
          description: 'Sugar synthesis in Calvin cycle',
          position: 3,
        ),
        ConceptPiece(
          id: 'p5',
          label: 'Oxygen Release',
          description: 'Byproduct of water splitting',
          position: 4,
        ),
      ];
      orderedPieces = List.from(conceptPieces);
      connections = [
        ConceptConnection(fromId: 'p1', toId: 'p3', label: 'activates'),
        ConceptConnection(fromId: 'p3', toId: 'p5', label: 'produces'),
        ConceptConnection(fromId: 'p2', toId: 'p4', label: 'feeds'),
      ];
    });
  }

  void _initializeGraph() {
    // Create nodes from concept pieces arranged in a circle
    graphModel.nodes.clear();
    graphModel.edges.clear();

    const canvasWidth = 400.0;
    const canvasHeight = 400.0;
    final centerX = canvasWidth / 2;
    final centerY = canvasHeight / 2;
    final radius = min(canvasWidth, canvasHeight) / 3;

    for (int i = 0; i < conceptPieces.length; i++) {
      final piece = conceptPieces[i];
      final angle = (i / conceptPieces.length) * 2 * pi;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      final node = GraphNode(
        id: piece.id,
        x: x,
        y: y,
        text: piece.label,
        description: piece.description,
      );
      graphModel.addNode(node);
    }
  }

  Future<void> _submitSelfAssessment() async {
    if (priorKnowledgeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please share what you know')),
      );
      return;
    }

    setState(() => isSubmittingSelfAssessment = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/assess-prior-knowledge'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': currentTopic,
              'priorKnowledge': priorKnowledgeController.text,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final feedback = jsonDecode(response.body);
        setState(() {
          assessmentFeedback = feedback;
          currentPhase = ConceptPhase.conceptAssembly;
          isSubmittingSelfAssessment = false;
        });
      } else {
        setState(() => isSubmittingSelfAssessment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error assessing knowledge')),
        );
      }
    } catch (e) {
      setState(() => isSubmittingSelfAssessment = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitConceptMap() async {
    if (userConnections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw at least one connection')),
      );
      return;
    }

    setState(() => currentPhase = ConceptPhase.testModel);
    _generateScenario();
  }

  void _generateScenario() {
    // Simplified scenario generation - in production, call backend
    final removedPiece = orderedPieces[orderedPieces.length ~/ 2];
    setState(() {
      scenarioQuestion =
          'What would happen if we removed "${removedPiece.label}" from the process?';
    });
  }

  Future<void> _submitPrediction() async {
    if (predictionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please make a prediction')));
      return;
    }

    setState(() => isSubmittingPrediction = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/evaluate-scenario-prediction'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': currentTopic,
              'scenario': scenarioQuestion,
              'prediction': predictionController.text,
              'conceptMap': {
                'pieces': orderedPieces.map((p) => p.label).toList(),
                'connections': userConnections
                    .map(
                      (c) => {
                        'from': orderedPieces
                            .firstWhere((p) => p.id == c.fromId)
                            .label,
                        'to': orderedPieces
                            .firstWhere((p) => p.id == c.toId)
                            .label,
                        'label': c.label,
                      },
                    )
                    .toList(),
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final feedback = jsonDecode(response.body);
        setState(() {
          scenarioFeedback = feedback;
          currentPhase = ConceptPhase.teachBack;
          isSubmittingPrediction = false;
        });
      } else {
        setState(() => isSubmittingPrediction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error evaluating prediction')),
        );
      }
    } catch (e) {
      setState(() => isSubmittingPrediction = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitTeachBack() async {
    if (teachBackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please explain the concept')),
      );
      return;
    }

    setState(() => isSubmittingTeachBack = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ScoringService.baseUrl}/score-teach-back'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': currentTopic,
              'teachBackExplanation': teachBackController.text,
              'priorKnowledge': priorKnowledgeController.text,
              'conceptMapSize': orderedPieces.length,
              'connectionCount': userConnections.length,
              'confusionFlags': confusionFlags.toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      setState(() => isSubmittingTeachBack = false);

      if (response.statusCode == 200) {
        final scores = jsonDecode(response.body);
        _calculateFinalScores(scores);
      } else {
        _calculateFinalScores({});
      }
    } catch (e) {
      setState(() => isSubmittingTeachBack = false);
      _calculateFinalScores({});
    }
  }

  void _calculateFinalScores(Map<String, dynamic> teachBackScores) {
    // Calculate comprehensive metrics
    final conceptualUnderstanding =
        ((teachBackScores['clarity'] ?? 5) + (teachBackScores['depth'] ?? 5)) /
        2;
    final connectionQuality = (userConnections.length / 10)
        .clamp(0, 10)
        .toDouble();
    final metacognitiveAwareness =
        ((confusionFlags.length * 2) + (assessmentFeedback?['gaps'] ?? 0)) / 2;

    final totalScore =
        ((conceptualUnderstanding * 0.4 +
                    connectionQuality * 0.3 +
                    metacognitiveAwareness * 0.3) /
                10 *
                100)
            .clamp(0, 100);

    final metricsDisplay = {
      'Conceptual Understanding': conceptualUnderstanding.toStringAsFixed(1),
      'Connection Quality': connectionQuality.toStringAsFixed(1),
      'Metacognitive Awareness': metacognitiveAwareness.toStringAsFixed(1),
    };

    setState(() {
      finalScores = teachBackScores;
      finalScore = totalScore;
      showingResults = true;
    });

    _showCompletionDialog(metricsDisplay, totalScore);
  }

  Future<void> _showCompletionDialog(
    Map<String, dynamic> metrics,
    double score,
  ) async {
    // Fetch actual user progress (coins already deducted on entry)
    final userProgress = await ProgressService.getProgress();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivityResultsDialog(
        activityName: widget.activity.name,
        score: score,
        progress: userProgress,
        metrics: metrics,
        onContinue: () {
          Navigator.pop(context);
          widget.onComplete();
        },
        onReview: () {
          Navigator.pop(context);
          _showAIReview();
        },
      ),
    );
  }

  void _showAIReview() {
    final reviewItems = [
      AIReviewItem(
        title: 'What should you learn next?',
        content: _generateLearningRecommendation(),
        icon: Icons.lightbulb,
        iconColor: Color(0xFFFFD93D),
      ),
      AIReviewItem(
        title: 'Gaps in knowledge',
        content: _generateGapsAnalysis(),
        icon: Icons.warning_outlined,
        iconColor: Color(0xFFFF922B),
      ),
      AIReviewItem(
        title: 'Strengths to build on',
        content: _generateStrengthsAnalysis(),
        icon: Icons.check_circle_outline,
        iconColor: Color(0xFF51CF66),
      ),
      AIReviewItem(
        title: 'Connection quality',
        content: _generateConnectionAnalysis(),
        icon: Icons.link,
        iconColor: Color(0xFF74C0FC),
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AIReviewPanel(
        activityName: 'Concept Cartographer - $currentTopic',
        overallInsight: _generateOverallInsight(),
        reviewItems: reviewItems,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _generateOverallInsight() {
    final nodeCount = graphModel.nodes.length;
    final edgeCount = graphModel.edges.length;
    final connectionRatio = nodeCount > 0 ? edgeCount / nodeCount : 0;

    if (connectionRatio > 1.5) {
      return 'Excellent work! You\'ve created a well-connected concept map with strong relationships between ideas. This shows deep understanding of how concepts interact.';
    } else if (connectionRatio > 0.8) {
      return 'Good progress! You\'ve identified key relationships between concepts. Consider adding more connections to show how different ideas relate.';
    } else {
      return 'You\'ve started building your concept map. Try connecting more concepts to reveal deeper relationships and patterns.';
    }
  }

  String _generateLearningRecommendation() {
    final underconnectedConcepts = graphModel.nodes
        .where((node) => graphModel.getConnectedEdges(node.id).length < 2)
        .map((n) => n.text)
        .toList();

    if (underconnectedConcepts.isEmpty) {
      return 'You\'ve made excellent connections! Consider exploring how these concepts apply to real-world scenarios.';
    }

    return 'Focus on understanding how ${underconnectedConcepts.join(', ')} relate to other concepts. These are key nodes that should have more connections.';
  }

  String _generateGapsAnalysis() {
    final edgeCount = graphModel.edges.length;
    if (edgeCount < 3) {
      return 'You\'ve drawn $edgeCount connection(s). Try to identify at least 3-4 meaningful relationships between concepts to build a comprehensive understanding.';
    }
    return 'Your connections are well-developed. Look for indirect relationships - concepts that influence each other through other concepts.';
  }

  String _generateStrengthsAnalysis() {
    final edgeCount = graphModel.edges.length;
    if (edgeCount > 0) {
      return 'Great! You\'ve identified $edgeCount meaningful relationships. Your ability to see connections between concepts demonstrates strong analytical thinking.';
    }
    return 'You\'ve organized the concepts logically. Now focus on identifying the relationships between them.';
  }

  String _generateConnectionAnalysis() {
    final edges = graphModel.edges;
    if (edges.isEmpty)
      return 'Start by identifying the first connection between two related concepts.';

    final labels = edges.map((e) => e.label).toList();
    final uniqueLabels = labels.toSet().length;

    if (uniqueLabels > 2) {
      return 'Excellent variety in your relationship labels ($uniqueLabels types). This shows nuanced understanding of different types of connections.';
    }
    return 'Consider using more varied relationship labels like "causes", "requires", "enables", "supports" to show different types of connections.';
  }

  void _toggleConfusionFlag(String pieceId) {
    setState(() {
      if (confusionFlags.contains(pieceId)) {
        confusionFlags.remove(pieceId);
      } else {
        confusionFlags.add(pieceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase indicator (only show after topic selection)
            if (currentPhase != ConceptPhase.topicSelection) ...[
              _buildPhaseIndicator(),
              SizedBox(height: 24),
            ],

            // Current phase content
            if (currentPhase == ConceptPhase.topicSelection)
              _buildTopicSelectionPhase()
            else if (currentPhase == ConceptPhase.selfAssessment)
              _buildSelfAssessmentPhase()
            else if (currentPhase == ConceptPhase.conceptAssembly)
              _buildConceptAssemblyPhase()
            else if (currentPhase == ConceptPhase.testModel)
              _buildTestModelPhase()
            else if (currentPhase == ConceptPhase.teachBack)
              _buildTeachBackPhase(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelectionPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you want to learn about?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
            color: Color(0xFF74C0FC),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Enter any topic and AI will create a concept map for you to explore. The AI will generate key concepts and show how they connect.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: topicInputController,
          enabled: !isLoadingTopic,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'e.g., Photosynthesis, Machine Learning, Ancient Rome...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[900],
            prefixIcon: Icon(Icons.lightbulb_outline, color: Color(0xFF74C0FC)),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoadingTopic
                ? null
                : () => _generateTopicFromInput(topicInputController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF74C0FC),
              padding: EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: isLoadingTopic
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'Generate Concept Map',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 32),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900]?.withOpacity(0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Ntype82-R',
                  color: Color(0xFF74C0FC),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '1. Enter any topic you\'re curious about\n'
                '2. AI generates 5 key concepts related to that topic\n'
                '3. You arrange them logically and draw connections\n'
                '4. Test your understanding with scenario predictions\n'
                '5. Teach back what you learned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Lettera',
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    final phases = [
      'Self-Assessment',
      'Concept Assembly',
      'Test Model',
      'Teach-Back',
    ];
    final currentIndex = ConceptPhase.values.indexOf(currentPhase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic: $currentTopic',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        SizedBox(height: 16),
        Row(
          children: List.generate(
            phases.length,
            (index) => Expanded(
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: index < currentIndex
                          ? Color(0xFF74C0FC)
                          : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    phases[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Lettera',
                      color: index < currentIndex
                          ? Color(0xFF74C0FC)
                          : Colors.grey[500],
                      fontSize: 10,
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

  Widget _buildSelfAssessmentPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 1: Self-Assessment',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
            color: Color(0xFF74C0FC),
          ),
        ),
        SizedBox(height: 12),
        Text(
          topicDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 24),
        Text(
          'What do you already know about this topic? Share any fragments, even if incomplete.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'Lettera'),
        ),
        SizedBox(height: 12),
        TextField(
          controller: priorKnowledgeController,
          maxLines: 5,
          minLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Share your current understanding...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        SizedBox(height: 24),
        if (assessmentFeedback != null) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF74C0FC).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Feedback:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Ntype82-R',
                    color: Color(0xFF74C0FC),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  assessmentFeedback!['feedback'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Lettera',
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSubmittingSelfAssessment
                ? null
                : _submitSelfAssessment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF74C0FC),
              padding: EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: isSubmittingSelfAssessment
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analyzing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Ntype82-R',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Continue to Concept Assembly',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConceptAssemblyPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 2: Concept Assembly',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
            color: Color(0xFF74C0FC),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Drag nodes to arrange them. Click nodes to select/deselect. Use "Draw Connection" to create relationships.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 24),
        // Graph Canvas
        GraphCanvasEnhanced(
          key: graphCanvasKey,
          graph: graphModel,
          height: 450,
          showInstructions: true,
          onGraphChanged: () {
            setState(() {
              // Update user connections from graph edges
              userConnections = graphModel.edges
                  .map(
                    (e) => ConceptConnection(
                      fromId: e.sourceId,
                      toId: e.targetId,
                      label: e.label,
                    ),
                  )
                  .toList();
            });
          },
        ),
        SizedBox(height: 24),
        // Control buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    graphModel.isDrawingEdge = !graphModel.isDrawingEdge;
                    if (!graphModel.isDrawingEdge) {
                      graphModel.edgeSourceNodeId = null;
                      graphModel.previewEdgeX = null;
                      graphModel.previewEdgeY = null;
                    }
                  });
                },
                icon: Icon(graphModel.isDrawingEdge ? Icons.close : Icons.link),
                label: Text(
                  graphModel.isDrawingEdge
                      ? 'Cancel Drawing'
                      : 'Draw Connection',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: graphModel.isDrawingEdge
                      ? Colors.red[700]
                      : Color(0xFF74C0FC),
                ),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Only delete connections, not nodes
                final selectedEdge = graphModel.edges.firstWhere(
                  (e) => e.isSelected,
                  orElse: () =>
                      GraphEdge(id: '', sourceId: '', targetId: '', label: ''),
                );
                if (selectedEdge.id.isNotEmpty) {
                  setState(() {
                    graphModel.removeEdge(selectedEdge.id);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tap a connection line to select it for deletion',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Connection'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            ),
          ],
        ),
        SizedBox(height: 24),
        // Connections list
        if (graphModel.edges.isNotEmpty) ...[
          Text(
            'Connections Created:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
          ),
          SizedBox(height: 12),
          ...graphModel.edges.map((edge) {
            final sourceNode = graphModel.getNode(edge.sourceId);
            final targetNode = graphModel.getNode(edge.targetId);
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green[700]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green[900]?.withOpacity(0.2),
              ),
              child: Text(
                '${sourceNode?.text ?? "?"} → ${edge.label} → ${targetNode?.text ?? "?"}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'Lettera'),
              ),
            );
          }),
          SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitConceptMap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF74C0FC),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Continue to Test Model',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Ntype82-R',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionBuilder() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900]?.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a Connection:',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'Ntype82-R'),
          ),
          SizedBox(height: 12),
          Text(
            'Step 1: Select FROM concept',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...orderedPieces.map((piece) {
                final isSelected = selectedFromId == piece.id;
                return FilterChip(
                  label: Text(piece.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedFromId = selected ? piece.id : null;
                    });
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: Color(0xFF74C0FC),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[300],
                    fontFamily: 'Lettera',
                  ),
                );
              }),
            ],
          ),
          if (selectedFromId != null) ...[
            SizedBox(height: 16),
            Text(
              'Step 2: Select TO concept',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...orderedPieces.map((piece) {
                  final isSelected = selectedToId == piece.id;
                  final isDisabled = piece.id == selectedFromId;
                  return FilterChip(
                    label: Text(piece.label),
                    selected: isSelected,
                    onSelected: isDisabled
                        ? null
                        : (selected) {
                            setState(() {
                              selectedToId = selected ? piece.id : null;
                            });
                          },
                    backgroundColor: isDisabled
                        ? Colors.grey[700]
                        : Colors.grey[800],
                    selectedColor: Color(0xFF74C0FC),
                    labelStyle: TextStyle(
                      color: isDisabled
                          ? Colors.grey[600]
                          : (isSelected ? Colors.black : Colors.grey[300]),
                      fontFamily: 'Lettera',
                    ),
                  );
                }),
              ],
            ),
          ],
          if (selectedFromId != null && selectedToId != null) ...[
            SizedBox(height: 16),
            Text(
              'Step 3: Describe the relationship',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Lettera',
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: connectionLabelController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'e.g., causes, requires, leads to, enables...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF74C0FC),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Add Connection',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Ntype82-R',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addConnection() {
    if (selectedFromId == null || selectedToId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both concepts')),
      );
      return;
    }

    if (connectionLabelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the relationship')),
      );
      return;
    }

    setState(() {
      userConnections.add(
        ConceptConnection(
          fromId: selectedFromId!,
          toId: selectedToId!,
          label: connectionLabelController.text.trim(),
        ),
      );
      selectedFromId = null;
      selectedToId = null;
      connectionLabelController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Connection added!')));
  }

  void _removeConnection(int index) {
    setState(() {
      userConnections.removeAt(index);
    });
  }

  Widget _buildTestModelPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 3: Test Your Model',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
            color: Color(0xFF74C0FC),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Based on your concept map, predict what would happen in this scenario:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF74C0FC).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
            color: Color(0xFF74C0FC).withOpacity(0.1),
          ),
          child: Text(
            scenarioQuestion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[200],
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Your Prediction:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
        ),
        SizedBox(height: 12),
        TextField(
          controller: predictionController,
          maxLines: 4,
          minLines: 3,
          maxLength: 250,
          decoration: InputDecoration(
            hintText: 'Explain what you think would happen...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        SizedBox(height: 24),
        if (scenarioFeedback != null) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[700]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Feedback:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Ntype82-R',
                    color: Colors.green[400],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  scenarioFeedback!['feedback'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Lettera',
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSubmittingPrediction ? null : _submitPrediction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF74C0FC),
              padding: EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: isSubmittingPrediction
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Evaluating...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Ntype82-R',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Continue to Teach-Back',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeachBackPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 4: Teach-Back',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Ntype82-R',
            color: Color(0xFF74C0FC),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Explain the concept in 100-150 words. Imagine you\'re teaching someone who knows nothing about it.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: teachBackController,
          maxLines: 6,
          minLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Explain the concept in your own words...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSubmittingTeachBack ? null : _submitTeachBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF74C0FC),
              padding: EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: isSubmittingTeachBack
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Scoring...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Ntype82-R',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Complete Activity',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
