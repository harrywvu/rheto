import 'dart:async';
import 'package:flutter/material.dart';

class QuizScreenCreativity extends StatefulWidget {
  final VoidCallback onComplete;
  const QuizScreenCreativity({super.key, required this.onComplete});

  @override
  State<QuizScreenCreativity> createState() => _QuizScreenCreativityState();
}

enum CreativityPhase { initial, twist, refinement }

class _QuizScreenCreativityState extends State<QuizScreenCreativity> {
  // Phase management
  CreativityPhase _phase = CreativityPhase.initial;
  
  // Timer management
  Timer? _timer;
  int _secondsRemaining = 90;
  
  // Text input
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _refinementController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _refinementFocusNode = FocusNode();
  
  // Ideas tracking
  final List<String> _userIdeas = [];
  String _refinedIdea = '';
  
  // Constants
  static const int _twistDuration = 30;
  static const int _refinementDuration = 45;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _refinementController.dispose();
    _focusNode.dispose();
    _refinementFocusNode.dispose();
    super.dispose();
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
        case CreativityPhase.initial:
          _phase = CreativityPhase.twist;
          _secondsRemaining = _twistDuration;
          break;
        case CreativityPhase.twist:
          _phase = CreativityPhase.refinement;
          _secondsRemaining = _refinementDuration;
          break;
        case CreativityPhase.refinement:
          _onComplete();
          break;
      }
    });

    if (_phase == CreativityPhase.twist) {
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    } else if (_phase == CreativityPhase.refinement) {
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refinementFocusNode.requestFocus();
      });
    }
  }

  // ========== PHASE TRANSITIONS ==========

  void _onMoveToTwist() {
    if (_userIdeas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one idea first!')),
      );
      return;
    }
    
    _timer?.cancel();
    setState(() {
      _phase = CreativityPhase.twist;
      _secondsRemaining = _twistDuration;
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onMoveToRefinement() {
    if (_userIdeas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one idea first!')),
      );
      return;
    }
    
    _timer?.cancel();
    setState(() {
      _phase = CreativityPhase.refinement;
      _secondsRemaining = _refinementDuration;
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refinementFocusNode.requestFocus();
    });
  }

  void _onComplete() {
    print("User Ideas: ${_userIdeas.join(", ")}");
    print("Refined Idea: $_refinedIdea");
    widget.onComplete();
  }

  // ========== IDEA SUBMISSION HANDLERS ==========

  void _handleIdeaSubmission(String text) {
    final trimmedInput = text.trim();

    if (trimmedInput.isEmpty) {
      _textController.clear();
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _userIdeas.add(trimmedInput);
    });

    _textController.clear();
    _focusNode.requestFocus();
  }

  void _handleRefinementSubmission(String text) {
    final trimmedInput = text.trim();

    if (trimmedInput.isEmpty) {
      return;
    }

    setState(() {
      _refinedIdea = trimmedInput;
    });
  }

  // ========== UI BUILDERS ==========

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case CreativityPhase.initial:
        return _buildInitialPhase();
      case CreativityPhase.twist:
        return _buildTwistPhase();
      case CreativityPhase.refinement:
        return _buildRefinementPhase();
    }
  }

  Widget _buildInitialPhase() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildTitle("List every new use for a brick you can think of."),
            const SizedBox(height: 8),
            _buildTimer(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _textController,
              focusNode: _focusNode,
              onSubmitted: _handleIdeaSubmission,
              hintText: 'Type an idea and press Enter...',
            ),
            const SizedBox(height: 24),
            _buildIdeasList(),
            const SizedBox(height: 16),
            _buildNextButton("Continue to Twist", _onMoveToTwist),
          ],
        ),
      ),
    );
  }

  Widget _buildTwistPhase() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildBanner("Zero-gravity station—add 3 more."),
            const SizedBox(height: 8),
            _buildTimer(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _textController,
              focusNode: _focusNode,
              onSubmitted: _handleIdeaSubmission,
              hintText: 'Type an idea and press Enter...',
            ),
            const SizedBox(height: 24),
            _buildIdeasList(),
            const SizedBox(height: 16),
            _buildNextButton("Continue to Refinement", _onMoveToRefinement),
          ],
        ),
      ),
    );
  }

  Widget _buildRefinementPhase() {
    final firstIdea = _userIdeas.isNotEmpty ? _userIdeas.first : "No ideas yet";
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildTitle("Improve your first idea in one sentence."),
            const SizedBox(height: 8),
            _buildTimer(),
            const SizedBox(height: 24),
            _buildFirstIdeaDisplay(firstIdea),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _refinementController,
              focusNode: _refinementFocusNode,
              onSubmitted: _handleRefinementSubmission,
              hintText: 'Type your improvement...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (_refinedIdea.isNotEmpty) _buildRefinedIdeaDisplay(),
            const SizedBox(height: 16),
            _buildFinishButton(),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET COMPONENTS ==========

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: 'Lettera',
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF74C0FC).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF74C0FC), width: 2),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: 'Lettera',
          fontWeight: FontWeight.bold,
          color: const Color(0xFF74C0FC),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeString = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _secondsRemaining <= 10 ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          timeString,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'Lettera',
            fontWeight: FontWeight.bold,
            color: _secondsRemaining <= 10 ? Colors.red : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onSubmitted,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF74C0FC), width: 2),
        ),
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontFamily: 'Lettera',
      ),
    );
  }

  Widget _buildIdeasList() {
    if (_userIdeas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Your ideas will appear here...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Lettera',
            color: Colors.grey, 
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Ideas (${_userIdeas.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'Lettera',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._userIdeas.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Lettera',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Lettera',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFirstIdeaDisplay(String idea) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3BF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD43B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your First Idea:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'Lettera',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            idea,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'Lettera',
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedIdeaDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD0EBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF74C0FC), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Improvement:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'Lettera',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _refinedIdea,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'Lettera',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF74C0FC),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Lettera',
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    return ElevatedButton(
      onPressed: _onComplete,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF008000),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        "Finish",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Lettera',
          color: Colors.white,
        ),
      ),
    );
  }
}
