# Graph Canvas Integration Checklist

## Current Status
✅ Graph models created (`lib/models/graph_models.dart`)
✅ Basic painter implemented (`lib/widgets/graph_painter.dart`)
✅ Basic canvas widget created (`lib/widgets/graph_canvas.dart`)
✅ Enhanced canvas with UX polish (`lib/widgets/graph_canvas_enhanced.dart`)
✅ Performance optimizations implemented
✅ Mobile/desktop considerations added

## Integration Steps

### Step 1: Update Concept Cartographer Imports
In `lib/screens/concept_cartographer_screen.dart`:

```dart
import 'package:rheto/widgets/graph_canvas_enhanced.dart';  // Use enhanced version
```

### Step 2: Replace GraphCanvas with GraphCanvasEnhanced
Find the `_buildConceptAssemblyPhase()` method and update:

```dart
// OLD:
GraphCanvas(
  key: graphCanvasKey,
  graph: graphModel,
  height: 450,
  onGraphChanged: () { ... },
)

// NEW:
GraphCanvasEnhanced(
  key: graphCanvasKey,
  graph: graphModel,
  height: 450,
  showInstructions: true,  // Show overlay on first load
  onGraphChanged: () {
    setState(() {
      userConnections = graphModel.edges
          .map((e) => ConceptConnection(
            fromId: e.sourceId,
            toId: e.targetId,
            label: e.label,
          ))
          .toList();
    });
  },
)
```

### Step 3: Update Control Buttons
The enhanced canvas has the same public methods:
- `toggleEdgeDrawingMode()`
- `deleteSelected()`

No changes needed to button handlers.

### Step 4: Test on Multiple Devices
- [ ] Test on Android phone (5.5" screen)
- [ ] Test on iPad (10" screen)
- [ ] Test on desktop (web)
- [ ] Verify touch targets are appropriate
- [ ] Verify instructions display correctly

### Step 5: Verify Features
- [ ] Drag nodes smoothly
- [ ] Create connections with labels
- [ ] Delete nodes and edges
- [ ] Select/deselect items
- [ ] Instructions overlay appears and dismisses
- [ ] Mobile context menu works (long-press)
- [ ] Edge labels display correctly

## Optional Enhancements

### Add Keyboard Support (Desktop)
```dart
// In graph_canvas_enhanced.dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Add keyboard listener
  RawKeyboardListener(
    focusNode: FocusNode(),
    onKey: _handleKeyPress,
    child: // ... canvas ...
  );
}

void _handleKeyPress(RawKeyEvent event) {
  if (event.isKeyPressed(LogicalKeyboardKey.delete)) {
    deleteSelected();
  }
}
```

### Add Undo/Redo
```dart
// Create history manager
class GraphHistory {
  final List<GraphModel> states = [];
  int currentIndex = -1;
  
  void push(GraphModel state) {
    // Remove any redo states
    states.removeRange(currentIndex + 1, states.length);
    states.add(state);
    currentIndex++;
  }
  
  void undo() {
    if (currentIndex > 0) currentIndex--;
  }
  
  void redo() {
    if (currentIndex < states.length - 1) currentIndex++;
  }
}
```

### Add Node Connection Count Badge
In `graph_painter.dart`, add to `_drawNodes()`:

```dart
// Draw connection count badge
final connectionCount = graph.getConnectedEdges(node.id).length;
if (connectionCount > 0) {
  final badgePaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(node.x + GraphNode.radius - 8, node.y - GraphNode.radius + 8),
    8,
    badgePaint,
  );
  
  // Draw count text
  final textPainter = TextPainter(
    text: TextSpan(
      text: '$connectionCount',
      style: const TextStyle(color: Colors.white, fontSize: 10),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      node.x + GraphNode.radius - 8 - textPainter.width / 2,
      node.y - GraphNode.radius + 8 - textPainter.height / 2,
    ),
  );
}
```

### Add Pulsing Animation for Unconnected Nodes
```dart
// In graph_canvas_enhanced.dart
// Already has _pulseController initialized

// Use in painter:
// In _drawNodes(), for nodes with no connections:
if (graph.getConnectedEdges(node.id).isEmpty) {
  final pulse = sin(_pulseController.value * 2 * pi) * 0.3 + 0.7;
  nodePaint.color = nodeColor.withOpacity(pulse);
}
```

## Performance Testing

### Benchmark Commands
```bash
# Profile on Android
flutter run --profile

# Profile on iOS
flutter run --profile -t lib/main.dart

# Web profiling
flutter run -d chrome --profile
```

### Expected Results
- **5 nodes:** 60 FPS (smooth)
- **20 nodes:** 55-60 FPS (smooth)
- **50 nodes:** 45-55 FPS (acceptable)

## Troubleshooting

### Issue: Nodes not dragging smoothly
**Solution:** Check if `_graph.draggingNodeId` is being cleared properly in `_handlePanEnd()`

### Issue: Connections not creating
**Solution:** Verify `_graph.isDrawingEdge` is true and source node is selected

### Issue: Instructions overlay not showing
**Solution:** Ensure `showInstructions: true` is passed to `GraphCanvasEnhanced`

### Issue: Mobile touch targets too small
**Solution:** Increase `_nodeRadius` in `initState()` or adjust platform detection

## Files Modified/Created

| File | Status | Purpose |
|------|--------|---------|
| `lib/models/graph_models.dart` | ✅ Created | Data models with caching |
| `lib/widgets/graph_painter.dart` | ✅ Created | Canvas rendering |
| `lib/widgets/graph_canvas.dart` | ✅ Created | Basic interactive canvas |
| `lib/widgets/graph_canvas_enhanced.dart` | ✅ Created | Enhanced with UX polish |
| `lib/screens/concept_cartographer_screen.dart` | 🔄 Ready to update | Integration point |

## Next Steps

1. **Test the enhanced canvas** with current implementation
2. **Gather user feedback** on mobile vs desktop experience
3. **Implement optional enhancements** based on feedback
4. **Profile performance** on target devices
5. **Optimize further** if needed (spatial indexing, culling, etc.)

## Success Criteria

- [ ] Graph canvas renders smoothly on all devices
- [ ] Drag operations maintain 55+ FPS
- [ ] Touch targets are appropriately sized
- [ ] Instructions are clear and dismissible
- [ ] All interactions work as expected
- [ ] No crashes or memory leaks
- [ ] Performance acceptable for 50+ nodes
