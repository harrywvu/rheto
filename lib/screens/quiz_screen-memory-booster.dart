import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rheto/hard-coded-lists/randomWords.dart';

class QuizScreenMemoryBooster extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(Map<String, dynamic>)? onDataCollected;
  const QuizScreenMemoryBooster({
    super.key,
    required this.onComplete,
    this.onDataCollected,
  });


  @override
  _QuizScreenMemoryBoosterState createState() =>
      _QuizScreenMemoryBoosterState();
}

enum Phase { display, immediateRecall, distract, delayedRecall }

class _QuizScreenMemoryBoosterState extends State<QuizScreenMemoryBooster> {
  // Phase management
  Phase _phase = Phase.display;

  // Timer management
  Timer? _timer;
  int _secondsRemaining = 8;

  // Text input
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Word recall tracking
  final Set<String> _immediateUserAnswers = {};
  final Set<String> _delayedUserAnswers = {};
  final List<String> _wordsList = [];
  DateTime? _recallStartTime;
  final List<double> _immediateRecallTimes = [];
  final List<double> _delayedRecallTimes = [];

  // Stroop test
  StroopPair? _currentStroopPair;
  late final StroopPairGenerator _stroopGenerator;

  // Constants
  static const int _displayDuration = 8;
  static const int _distractDuration = 30;
  static const int _maxWords = 10;

  @override
  void initState() {
    super.initState();
    _initializeWordsList();
    _initializeStroopGenerator();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ========== INITIALIZATION ==========

  void _initializeWordsList() {
    final random = Random();
    while (_wordsList.length < _maxWords) {
      final randomIndex = random.nextInt(masterWordsList.length);
      final word = masterWordsList[randomIndex];
      if (!_wordsList.contains(word)) {
        _wordsList.add(word);
      }
    }
  }

  void _initializeStroopGenerator() {
    const colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.white,
      Colors.pink,
    ];
    const colorNames = [
      "Red",
      "Green",
      "Blue",
      "Yellow",
      "Orange",
      "White",
      "Pink",
    ];
    _stroopGenerator = StroopPairGenerator(colorNames, colors);
  }

  // ========== TIMER MANAGEMENT ==========

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      switch (_phase) {
        case Phase.display:
          _phase = Phase.immediateRecall;
          _recallStartTime = DateTime.now();
          break;
        case Phase.distract:
          _phase = Phase.delayedRecall;
          _recallStartTime = DateTime.now(); // reset timer for delayed recall
          break;
        default:
          break;
      }
    });
  }

  // ========== PHASE TRANSITIONS ==========

  void _onFinishImmediateRecall() {
    setState(() {
      _phase = Phase.distract;
      _secondsRemaining = _distractDuration;
      _currentStroopPair = _stroopGenerator.getStroopPair();
    });
    _startTimer();
    // Keep focus on text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // temporary
  void _onFinishDelayedRecall() {
    // Debug logging for memory metrics
    print("MEMORY METRICS DEBUG:");
    print("Words List: ${_wordsList.join(", ")}");
    print("Immediate Recall: ${_immediateUserAnswers.join(", ")}");
    print("Delayed Recall: ${_delayedUserAnswers.join(", ")}");
    print("Immediate Recall Times: ${_immediateRecallTimes.join(", ")}");
    print("Delayed Recall Times: ${_delayedRecallTimes.join(", ")}");

    // Calculate metrics
    // Accuracy should be percentage (0-100), not absolute count
    final immediateAccuracy = (_immediateUserAnswers.length / _wordsList.length) * 100;
    final delayedAccuracy = (_delayedUserAnswers.length / _wordsList.length) * 100;
    
    // Retention curve is ratio of delayed to immediate recall (0-1)
    final retentionCurve = _immediateUserAnswers.isEmpty
        ? 0.0
        : (_delayedUserAnswers.length / _immediateUserAnswers.length);
    
    // Average recall time - if no words recalled, use a high value (10 seconds)
    // to ensure a low score
    final averageRecallTime = _immediateRecallTimes.isEmpty
        ? 10.0
        : _immediateRecallTimes.reduce((a, b) => a + b) /
            _immediateRecallTimes.length;
            
    // Debug logging for calculated metrics
    print("CALCULATED METRICS:");
    print("Immediate Accuracy: $immediateAccuracy%");
    print("Delayed Accuracy: $delayedAccuracy%");
    print("Retention Curve: $retentionCurve");
    print("Average Recall Time: $averageRecallTime seconds");
    print("Expected Score: ${(immediateAccuracy * retentionCurve) / (averageRecallTime / 10)}");

    // Pass data back to parent
    if (widget.onDataCollected != null) {
      widget.onDataCollected!({
        'immediateRecallAccuracy': immediateAccuracy,
        'delayedRecallAccuracy': delayedAccuracy,
        'retentionCurve': retentionCurve,
        'averageRecallTime': averageRecallTime,
        'immediateUserAnswers': _immediateUserAnswers.toList(),
        'delayedUserAnswers': _delayedUserAnswers.toList(),
      });
    }

    widget.onComplete();
  }

  // ========== WORD RECALL HANDLERS ==========

  void _handleWordSubmission(String text) {
    final trimmedInput = text.trim().toLowerCase();

    if (trimmedInput.isEmpty) {
      _textController.clear();
      _focusNode.requestFocus();
      return;
    }

    final now = DateTime.now();
    final elapsed = _recallStartTime != null
        ? now.difference(_recallStartTime!).inMilliseconds / 1000.0
        : 0.0;

    for (final word in _wordsList) {
      if (trimmedInput == word.toLowerCase()) {
        setState(() {
          if (_phase == Phase.immediateRecall &&
              !_immediateUserAnswers.contains(word)) {
            _immediateUserAnswers.add(word);
            _immediateRecallTimes.add(elapsed);
          } else if (_phase == Phase.delayedRecall &&
              !_delayedUserAnswers.contains(word)) {
            _delayedUserAnswers.add(word);
            _delayedRecallTimes.add(elapsed);
          }
        });
        break;
      }
    }

    _textController.clear();
    _focusNode.requestFocus();
  }

  // ========== STROOP TEST HANDLERS ==========

  void _handleStroopSubmission(String value) {
    setState(() {
      _currentStroopPair = _stroopGenerator.getStroopPair();
    });
    _textController.clear();
    _focusNode.requestFocus();
  }

  // ========== UI BUILDERS ==========

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case Phase.display:
        return _buildDisplayPhase();
      case Phase.immediateRecall:
        return _buildImmediateRecallPhase();
      case Phase.distract:
        return _buildDistractPhase();
      case Phase.delayedRecall:
        return _buildDelayedRecallPhase();
    }
  }

  Widget _buildDisplayPhase() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          _buildTitle("Memorize as many words as possible!"),
          const SizedBox(height: 16),
          _buildWordChips(showAll: true),
          const SizedBox(height: 16),
          _buildTimer(),
        ],
      ),
    );
  }

  Widget _buildImmediateRecallPhase() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTitle("Recall as many words as possible!"),
            const SizedBox(height: 16),
            _buildWordChips(showAll: false),
            const SizedBox(height: 16),
            _buildTextField(
              onSubmitted: _handleWordSubmission,
              hintText: 'Type your answer here...',
            ),
            const SizedBox(height: 16),
            _buildFinishButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractPhase() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTitle("Identify the color of the word, not the word itself."),
            const SizedBox(height: 32),
            if (_currentStroopPair != null) _buildStroopWord(),
            const SizedBox(height: 32),
            _buildTextField(
              onSubmitted: _handleStroopSubmission,
              hintText: 'Enter the color',
            ),
            const SizedBox(height: 16),
            _buildTimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayedRecallPhase() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTitle(
              "Type as many words as you remember from the earlier list.",
            ),
            const SizedBox(height: 16),
            _buildWordChips(showAll: false),
            const SizedBox(height: 16),
            _buildTextField(
              onSubmitted: _handleWordSubmission,
              hintText: 'Type your answer here...',
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _onFinishDelayedRecall,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008000),
              ),
              child: Text(
                "Finish",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET COMPONENTS ==========

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontFamily: 'Lettera'),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWordChips({required bool showAll}) {
    final currentAnswers = _phase == Phase.delayedRecall
        ? _delayedUserAnswers
        : _immediateUserAnswers;

    final chips = _wordsList.map((word) {
      final isRecalled = currentAnswers.contains(word);
      final shouldShow = showAll || isRecalled;

      return Chip(
        label: Text(shouldShow ? word : ''),
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: isRecalled ? Colors.green : null,
        labelStyle: isRecalled ? const TextStyle(color: Colors.white) : null,
      );
    }).toList();

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildTextField({
    required void Function(String) onSubmitted,
    required String hintText,
  }) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      autofocus: true,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF74C0FC), width: 2),
        ),
      ),
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
    );
  }

  Widget _buildFinishButton() {
    return ElevatedButton(
      onPressed: _onFinishImmediateRecall,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008000)),
      child: Text("Finish", style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildTimer() {
    return Text(
      _phase == Phase.distract
          ? 'Time remaining: $_secondsRemaining seconds'
          : '$_secondsRemaining',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontFamily: 'Lettera'),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStroopWord() {
    return Text(
      _currentStroopPair!.name,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontFamily: 'Lettera',
        color: _currentStroopPair!.color,
        fontSize: 72,
      ),
    );
  }
}

// ========== STROOP TEST CLASSES ==========

class StroopPair {
  final Color color;
  final String name;

  StroopPair(this.color, this.name);
}

class StroopPairGenerator {
  final List<String> names;
  final List<Color> colors;
  final Random _random = Random();

  StroopPairGenerator(this.names, this.colors) {
    if (names.length != colors.length) {
      throw ArgumentError('Lists must have the same length');
    }
    if (names.length < 2) {
      throw ArgumentError('Lists must have at least 2 items');
    }
  }

  StroopPair getStroopPair() {
    int colorIndex = _random.nextInt(colors.length);
    int nameIndex = _random.nextInt(names.length);

    // Ensure name and color don't match
    while (nameIndex == colorIndex) {
      nameIndex = _random.nextInt(names.length);
    }

    return StroopPair(colors[colorIndex], names[nameIndex]);
  }
}
