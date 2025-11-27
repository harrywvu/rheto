import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContradictionHunterReviewScreen extends StatefulWidget {
  final String story;
  final List<String> storysentences;
  final Set<int> userSelectedIndices;
  final Set<int> correctSentenceIndices;

  const ContradictionHunterReviewScreen({
    super.key,
    required this.story,
    required this.storysentences,
    required this.userSelectedIndices,
    required this.correctSentenceIndices,
  });

  @override
  State<ContradictionHunterReviewScreen> createState() =>
      _ContradictionHunterReviewScreenState();
}

class _ContradictionHunterReviewScreenState
    extends State<ContradictionHunterReviewScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final incorrectIndices = widget.userSelectedIndices
        .where((idx) => !widget.correctSentenceIndices.contains(idx))
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
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
                    'Legend',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFF63E6BE).withOpacity(0.3),
                          border: Border.all(color: Color(0xFF63E6BE)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Correct contradictions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B6B).withOpacity(0.2),
                          border: Border.all(
                            color: Color(0xFFFF6B6B).withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Incorrect selections',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD43B).withOpacity(0.15),
                          border: Border.all(
                            color: Color(0xFFFFD43B).withOpacity(0.6),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Missed contradictions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Story display with highlighting
            Text(
              'Your Analysis',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
            ),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
              ),
              child: _buildReviewSentences(
                widget.correctSentenceIndices,
                incorrectIndices,
              ),
            ),
            SizedBox(height: 24),

            // Summary stats
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
                    'Summary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Correct Selections',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF63E6BE).withOpacity(0.15),
                          border: Border.all(color: Color(0xFF63E6BE)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.userSelectedIndices.where((idx) => widget.correctSentenceIndices.contains(idx)).length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'NType82-R',
                                color: Color(0xFF63E6BE),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Incorrect Selections',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B6B).withOpacity(0.15),
                          border: Border.all(
                            color: Color(0xFFFF6B6B).withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${incorrectIndices.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'NType82-R',
                                color: Color(0xFFFF6B6B),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Missed Contradictions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Lettera',
                          color: Colors.grey[300],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD43B).withOpacity(0.15),
                          border: Border.all(
                            color: Color(0xFFFFD43B).withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.correctSentenceIndices.where((idx) => !widget.userSelectedIndices.contains(idx)).length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'NType82-R',
                                color: Color(0xFFFFD43B),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Quit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop review screen, then pop activity screen, then pop to home
                  Navigator.pop(context); // Close review
                  Navigator.pop(context); // Close activity
                  Navigator.pop(context); // Go to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF74C0FC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.home,
                      color: Colors.black,
                      size: 16,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Return to Home',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      ),
    );
  }

  Widget _buildReviewSentences(
    Set<int> correctIndices,
    Set<int> incorrectIndices,
  ) {
    final missedIndices = correctIndices
        .where((idx) => !widget.userSelectedIndices.contains(idx))
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.storysentences.length, (index) {
        final sentence = widget.storysentences[index];
        final isCorrect = correctIndices.contains(index);
        final isIncorrect = incorrectIndices.contains(index);
        final isMissed = missedIndices.contains(index);
        final wasSelected = widget.userSelectedIndices.contains(index);

        Color backgroundColor = Colors.transparent;
        Color textColor = Colors.grey[200]!;
        Color borderColor = Colors.transparent;

        if (isCorrect && wasSelected) {
          // Correct selection - green
          backgroundColor = Color(0xFF63E6BE).withOpacity(0.2);
          borderColor = Color(0xFF63E6BE);
          textColor = Color(0xFF63E6BE);
        } else if (isIncorrect && wasSelected) {
          // Incorrect selection - faded red
          backgroundColor = Color(0xFFFF6B6B).withOpacity(0.15);
          borderColor = Color(0xFFFF6B6B).withOpacity(0.5);
          textColor = Color(0xFFFF6B6B).withOpacity(0.8);
        } else if (isMissed) {
          // Missed contradiction - yellow/gold
          backgroundColor = Color(0xFFFFD43B).withOpacity(0.15);
          borderColor = Color(0xFFFFD43B).withOpacity(0.6);
          textColor = Color(0xFFFFD43B);
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: borderColor != Colors.transparent
                ? Border.all(color: borderColor, width: 1)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: RichText(
            text: TextSpan(
              text:
                  sentence +
                  (index < widget.storysentences.length - 1 ? ' ' : ''),
              style: TextStyle(
                fontFamily: 'Lettera',
                fontSize: 16,
                height: 1.8,
                color: textColor,
                fontWeight: (wasSelected || isMissed)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
