# AI Review & Coaching System Implementation

## Overview

The AI Review system provides comprehensive feedback and coaching for activities. It includes:
- **Node Information Modal** - Learn definitions of concepts by tapping nodes
- **AI Review Panel** - Collapsible feedback sections with AI insights and coaching
- **Integration with Activity Results** - Seamless review flow after activity completion

---

## Feature 1: Node Information Modal

### What It Does
When users tap a node (not dragging, not drawing connections), a beautiful modal appears showing:
- Node name with colored indicator
- Definition/description of the concept
- Learning tip encouraging connection-building
- Close button (click outside or button to dismiss)

### How to Use

#### 1. Add Description to Nodes
When initializing nodes in `_initializeGraph()`:

```dart
final node = GraphNode(
  id: piece.id,
  x: x,
  y: y,
  text: piece.label,
  description: piece.description, // Add this
);
graphModel.addNode(node);
```

#### 2. Node Tap Behavior
The enhanced canvas automatically:
- Detects taps on nodes
- Shows the modal with node information
- Allows closing by clicking outside or the close button

#### 3. Customizing the Modal
Edit `lib/widgets/node_info_modal.dart` to:
- Change colors and styling
- Add more information sections
- Modify the learning tip text

### Example Usage
```dart
// In concept_cartographer_screen.dart, _initializeGraph():
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
    description: piece.description, // From API
    color: nodeColor,
  );
  graphModel.addNode(node);
}
```

---

## Feature 2: AI Review Panel

### What It Does
Displays comprehensive AI feedback with:
- **Overall Insights** - High-level summary of performance
- **Detailed Feedback** - Collapsible sections for:
  - "What should you learn next?"
  - "What to do next?"
  - "Gaps in knowledge"
  - "Strengths to build on"
  - "Areas for improvement"
  - Custom coaching points

### How to Use

#### 1. Create Review Items
```dart
import 'package:rheto/widgets/ai_review_panel.dart';

final reviewItems = [
  AIReviewItem(
    title: 'What should you learn next?',
    content: 'Based on your concept map, you should deepen your understanding of...',
    icon: Icons.lightbulb,
    iconColor: Color(0xFFFFD93D),
  ),
  AIReviewItem(
    title: 'Gaps in knowledge',
    content: 'You haven\'t connected [concept] to [concept]. These are related because...',
    icon: Icons.warning_outlined,
    iconColor: Color(0xFFFF922B),
  ),
  AIReviewItem(
    title: 'Strengths to build on',
    content: 'Your connections between [concept] and [concept] show strong causal reasoning...',
    icon: Icons.check_circle_outline,
    iconColor: Color(0xFF51CF66),
  ),
];
```

#### 2. Show the Review Panel
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AIReviewPanel(
    activityName: 'Concept Cartographer',
    overallInsight: 'You demonstrated solid understanding of the core concepts...',
    reviewItems: reviewItems,
    onClose: () {
      Navigator.pop(context);
      // Navigate back to activities
    },
  ),
);
```

#### 3. Integrate with Activity Results Dialog
```dart
ActivityResultsDialog(
  activityName: widget.activity.name,
  score: finalScore,
  progress: userProgress,
  metrics: metricsDisplay,
  onContinue: () {
    Navigator.pop(context);
    Navigator.pop(context); // Back to activities
  },
  onReview: () {
    Navigator.pop(context); // Close results dialog
    _showAIReview(); // Show review panel
  },
)
```

---

## Complete Example: Concept Cartographer with AI Review

### Step 1: Update Concept Cartographer Screen

```dart
import 'package:rheto/widgets/ai_review_panel.dart';

class _ConceptCartographerScreenState extends State<ConceptCartographerScreen> {
  // ... existing code ...

  void _showAIReview() {
    // Generate review items based on user's concept map
    final reviewItems = _generateReviewItems();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AIReviewPanel(
        activityName: 'Concept Cartographer - ${currentTopic}',
        overallInsight: _generateOverallInsight(),
        reviewItems: reviewItems,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context); // Back to activities
        },
      ),
    );
  }

  List<AIReviewItem> _generateReviewItems() {
    return [
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
      AIReviewItem(
        title: 'Coaching tips',
        content: _generateCoachingTips(),
        icon: Icons.school,
        iconColor: Color(0xFFB197FC),
      ),
    ];
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
    // Analyze which concepts have few connections
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
      return 'You\'ve drawn ${edgeCount} connection(s). Try to identify at least 3-4 meaningful relationships between concepts to build a comprehensive understanding.';
    }
    return 'Your connections are well-developed. Look for indirect relationships - concepts that influence each other through other concepts.';
  }

  String _generateStrengthsAnalysis() {
    final edgeCount = graphModel.edges.length;
    if (edgeCount > 0) {
      return 'Great! You\'ve identified ${edgeCount} meaningful relationships. Your ability to see connections between concepts demonstrates strong analytical thinking.';
    }
    return 'You\'ve organized the concepts logically. Now focus on identifying the relationships between them.';
  }

  String _generateConnectionAnalysis() {
    final edges = graphModel.edges;
    if (edges.isEmpty) return 'Start by identifying the first connection between two related concepts.';
    
    final labels = edges.map((e) => e.label).toList();
    final uniqueLabels = labels.toSet().length;
    
    if (uniqueLabels > 2) {
      return 'Excellent variety in your relationship labels (${uniqueLabels} types). This shows nuanced understanding of different types of connections.';
    }
    return 'Consider using more varied relationship labels like "causes", "requires", "enables", "supports" to show different types of connections.';
  }

  String _generateCoachingTips() {
    return '''
1. **Look for causal chains**: How does one concept lead to another?
2. **Find bidirectional relationships**: Some concepts influence each other.
3. **Identify prerequisites**: What must be understood before learning another concept?
4. **Explore applications**: How do these concepts apply in the real world?
5. **Test your understanding**: Can you explain why two concepts are connected?
    ''';
  }
}
```

### Step 2: Update Activity Results Dialog Call

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
        Navigator.pop(context); // Back to activities
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

## Backend Integration (Optional)

For AI-powered review generation, add backend endpoint:

```javascript
// backend/server.js
app.post('/generate-activity-review', async (req, res) => {
  try {
    const { activityType, userResponses, correctAnswers } = req.body;
    
    const prompt = `Generate a detailed review for a ${activityType} activity.
User responses: ${JSON.stringify(userResponses)}
Correct answers: ${JSON.stringify(correctAnswers)}

Provide JSON with:
{
  "overallInsight": "...",
  "learningNext": "...",
  "gaps": "...",
  "strengths": "...",
  "coaching": "..."
}`;

    const response = await hf.textGeneration({
      model: 'openai/gpt-oss-20b:cheapest',
      inputs: prompt,
      parameters: { max_new_tokens: 500 }
    });

    const review = JSON.parse(response[0].generated_text);
    res.json(review);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## Customization Options

### Change Review Item Colors
```dart
AIReviewItem(
  title: 'Custom Title',
  content: 'Custom content',
  icon: Icons.star,
  iconColor: Color(0xFF51CF66), // Change this
)
```

### Add More Review Sections
```dart
reviewItems.addAll([
  AIReviewItem(
    title: 'Misconceptions to avoid',
    content: '...',
    icon: Icons.error_outline,
    iconColor: Color(0xFFFF922B),
  ),
  AIReviewItem(
    title: 'Real-world applications',
    content: '...',
    icon: Icons.public,
    iconColor: Color(0xFF74C0FC),
  ),
]);
```

### Customize Modal Appearance
Edit `node_info_modal.dart`:
- Change border color: `border: Border.all(color: Color(0xFF74C0FC))`
- Change background: `color: Colors.grey[900]`
- Change text styles and sizes

---

## Files Created/Modified

### New Files:
- `lib/widgets/node_info_modal.dart` - Node information modal
- `lib/widgets/ai_review_panel.dart` - AI review panel with collapsible sections
- `AI_REVIEW_IMPLEMENTATION.md` - This guide

### Modified Files:
- `lib/models/graph_models.dart` - Added `description` field to GraphNode
- `lib/widgets/graph_canvas_enhanced.dart` - Added node tap modal display

---

## User Flow

### Node Learning Flow:
1. User taps a node on the graph
2. Modal appears with node definition
3. User reads definition and learning tip
4. User closes modal by clicking outside or close button
5. User can tap another node or continue with activity

### Review Flow:
1. User completes activity
2. Results dialog appears with score and metrics
3. User clicks "Review" button
4. AI Review Panel opens with overall insights
5. User expands collapsible sections to read detailed feedback
6. User clicks "Back to Activities" to return

---

## Performance Considerations

- **Modal rendering**: Lightweight, no heavy computations
- **Collapsible sections**: Only one expanded at a time for smooth animations
- **Text rendering**: Uses standard Flutter text widgets
- **Memory**: Minimal overhead, review items are simple data objects

---

## Testing Checklist

- [ ] Node modal appears on tap
- [ ] Modal closes when clicking outside
- [ ] Modal closes when clicking close button
- [ ] Node description displays correctly
- [ ] Learning tip is visible and helpful
- [ ] Review panel opens from results dialog
- [ ] Collapsible sections expand/collapse smoothly
- [ ] All review items display correctly
- [ ] Close button works from review panel
- [ ] Colors and styling match design

---

## Next Steps

1. **Implement backend AI review generation** - Call AI to generate personalized feedback
2. **Add animations** - Smooth transitions between modals
3. **Add voice coaching** - Text-to-speech for review content
4. **Implement review history** - Save past reviews for comparison
5. **Add interactive elements** - Clickable concepts in review text
