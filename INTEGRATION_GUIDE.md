# Integration Guide: Node Modal & AI Review

## Quick Start (5 minutes)

### Step 1: Node Modal (Already Integrated!)
The node modal is **already working** in GraphCanvasEnhanced:
- Users tap nodes → modal appears
- Modal shows node description
- Click outside or close button to dismiss

**No additional code needed!** Just ensure nodes have descriptions.

### Step 2: Add Descriptions to Nodes
In `concept_cartographer_screen.dart`, update `_initializeGraph()`:

```dart
void _initializeGraph() {
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
      description: piece.description, // ← ADD THIS
      color: Color(0xFF74C0FC),
    );
    graphModel.addNode(node);
  }
}
```

---

## Step 3: Integrate AI Review Panel

### 3a. Add Import
In `concept_cartographer_screen.dart`:

```dart
import 'package:rheto/widgets/ai_review_panel.dart';
```

### 3b. Add Review Method
Add this method to `_ConceptCartographerScreenState`:

```dart
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
        Navigator.pop(context); // Back to activities
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
  if (edges.isEmpty) return 'Start by identifying the first connection between two related concepts.';
  
  final labels = edges.map((e) => e.label).toList();
  final uniqueLabels = labels.toSet().length;
  
  if (uniqueLabels > 2) {
    return 'Excellent variety in your relationship labels ($uniqueLabels types). This shows nuanced understanding of different types of connections.';
  }
  return 'Consider using more varied relationship labels like "causes", "requires", "enables", "supports" to show different types of connections.';
}
```

### 3c. Update Results Dialog
Find `_showCompletionDialog()` and update the `onReview` callback:

```dart
void _showCompletionDialog() {
  final metricsDisplay = {
    'Conceptual Understanding': conceptualUnderstanding.toStringAsFixed(1),
    'Connection Quality': connectionQuality.toStringAsFixed(1),
    'Metacognitive Awareness': metacognitiveAwareness.toStringAsFixed(1),
  };

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ActivityResultsDialog(
      activityName: widget.activity.name,
      score: finalScore,
      progress: userProgress,
      metrics: metricsDisplay,
      onContinue: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
      onReview: () {
        Navigator.pop(context); // Close results dialog
        _showAIReview(); // Show AI review panel
      },
    ),
  );
}
```

---

## Complete Example

Here's the complete integration for Concept Cartographer:

```dart
import 'package:rheto/widgets/ai_review_panel.dart';

// In _ConceptCartographerScreenState class:

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
  if (edges.isEmpty) return 'Start by identifying the first connection between two related concepts.';
  
  final labels = edges.map((e) => e.label).toList();
  final uniqueLabels = labels.toSet().length;
  
  if (uniqueLabels > 2) {
    return 'Excellent variety in your relationship labels ($uniqueLabels types). This shows nuanced understanding of different types of connections.';
  }
  return 'Consider using more varied relationship labels like "causes", "requires", "enables", "supports" to show different types of connections.';
}
```

---

## For Other Activities

### Use AI Review Panel in Any Activity

```dart
import 'package:rheto/widgets/ai_review_panel.dart';

// In your activity screen:
void _showReview() {
  final reviewItems = [
    AIReviewItem(
      title: 'What should you learn next?',
      content: 'Your specific recommendation here',
      icon: Icons.lightbulb,
      iconColor: Color(0xFFFFD93D),
    ),
    // Add more items...
  ];

  showDialog(
    context: context,
    builder: (context) => AIReviewPanel(
      activityName: 'Your Activity Name',
      overallInsight: 'Your overall feedback here',
      reviewItems: reviewItems,
      onClose: () => Navigator.pop(context),
    ),
  );
}
```

---

## Testing

### Test Node Modal
1. Run app and navigate to Concept Cartographer
2. Tap a node on the graph
3. Modal should appear with:
   - Node name
   - Description
   - Learning tip
   - Close button
4. Click outside modal → closes
5. Click close button → closes

### Test AI Review Panel
1. Complete Concept Cartographer activity
2. Results dialog appears
3. Click "Review" button
4. AI Review Panel opens with:
   - Overall Insights section
   - Collapsible feedback items
   - Smooth expand/collapse animations
5. Click "Back to Activities" → returns to activity list

---

## Customization

### Change Review Item Colors
```dart
AIReviewItem(
  title: 'Custom Title',
  content: 'Content',
  icon: Icons.star,
  iconColor: Color(0xFF51CF66), // Green
)
```

### Add More Review Sections
```dart
reviewItems.addAll([
  AIReviewItem(
    title: 'Real-world applications',
    content: 'How to apply this in practice...',
    icon: Icons.public,
    iconColor: Color(0xFF74C0FC),
  ),
]);
```

### Customize Modal Appearance
Edit `lib/widgets/node_info_modal.dart`:
- Change colors, fonts, sizes
- Add more sections
- Modify animations

---

## Files to Check

- ✅ `lib/widgets/node_info_modal.dart` - Node modal component
- ✅ `lib/widgets/ai_review_panel.dart` - Review panel component
- ✅ `lib/models/graph_models.dart` - GraphNode with description
- ✅ `lib/widgets/graph_canvas_enhanced.dart` - Modal integration
- 📝 `lib/screens/concept_cartographer_screen.dart` - Add review methods

---

## Summary

**Node Modal**: ✅ Already working - just add descriptions to nodes
**AI Review Panel**: ✅ Ready to integrate - add 3 methods + 1 import

**Total integration time**: ~15 minutes
**Difficulty**: Easy (mostly copy-paste)
**Result**: Beautiful learning experience with AI coaching!
