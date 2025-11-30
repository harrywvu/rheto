# Graph Canvas Customization Examples

## Common Customizations

### 1. Change Node Colors

**Scenario:** Different node types have different colors (e.g., input, process, output)

```dart
// In _initializeGraph() method
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

    // Assign colors based on piece type
    Color nodeColor = Color(0xFF74C0FC); // Default blue
    if (piece.label.contains('input')) {
      nodeColor = Color(0xFF51CF66); // Green for inputs
    } else if (piece.label.contains('output')) {
      nodeColor = Color(0xFFFF922B); // Orange for outputs
    }

    final node = GraphNode(
      id: piece.id,
      x: x,
      y: y,
      text: piece.label,
      color: nodeColor,
    );
    graphModel.addNode(node);
  }
}
```

### 2. Validate Connections

**Scenario:** Only allow certain node pairs to connect

```dart
// In graph_canvas_enhanced.dart, modify _createEdge()
void _createEdge(GraphNode targetNode, String label) {
  final sourceId = _graph.edgeSourceNodeId;
  if (sourceId == null || sourceId == targetNode.id) return;

  final sourceNode = _graph.getNode(sourceId);
  if (sourceNode == null) return;

  // Validation: prevent connecting same types
  if (sourceNode.text.split(' ')[0] == targetNode.text.split(' ')[0]) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot connect nodes of the same type')),
    );
    return;
  }

  // Validation: prevent duplicate connections
  final existingEdge = _graph.edges.firstWhere(
    (e) => e.sourceId == sourceId && e.targetId == targetNode.id,
    orElse: () => GraphEdge(id: '', sourceId: '', targetId: '', label: ''),
  );

  if (existingEdge.id.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection already exists')),
    );
    return;
  }

  // Create edge if validation passes
  final edgeId = 'edge_${DateTime.now().millisecondsSinceEpoch}';
  final edge = GraphEdge(
    id: edgeId,
    sourceId: sourceId,
    targetId: targetNode.id,
    label: label,
  );

  setState(() {
    _graph.addEdge(edge);
    _graph.edgeSourceNodeId = null;
    _graph.previewEdgeX = null;
    _graph.previewEdgeY = null;
    _graph.isDrawingEdge = false;
  });

  widget.onGraphChanged();
}
```

### 3. Add Node Descriptions on Hover (Desktop)

**Scenario:** Show tooltip with node description on mouse hover

```dart
// Create a custom widget wrapper
class GraphCanvasWithTooltips extends StatefulWidget {
  final GraphModel graph;
  final VoidCallback onGraphChanged;

  const GraphCanvasWithTooltips({
    required this.graph,
    required this.onGraphChanged,
  });

  @override
  State<GraphCanvasWithTooltips> createState() => _GraphCanvasWithTooltipsState();
}

class _GraphCanvasWithTooltipsState extends State<GraphCanvasWithTooltips> {
  String? _hoveredNodeId;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final position = event.localPosition;
        String? hoveredId;
        
        for (final node in widget.graph.nodes) {
          final dx = position.dx - node.x;
          final dy = position.dy - node.y;
          if (dx * dx + dy * dy <= 40 * 40) {
            hoveredId = node.id;
            break;
          }
        }

        if (hoveredId != _hoveredNodeId) {
          setState(() => _hoveredNodeId = hoveredId);
        }
      },
      child: Stack(
        children: [
          GraphCanvasEnhanced(
            graph: widget.graph,
            onGraphChanged: widget.onGraphChanged,
          ),
          if (_hoveredNodeId != null)
            _buildTooltip(_hoveredNodeId!),
        ],
      ),
    );
  }

  Widget _buildTooltip(String nodeId) {
    final node = widget.graph.getNode(nodeId);
    if (node == null) return SizedBox.shrink();

    return Positioned(
      left: node.x + 50,
      top: node.y,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Color(0xFF74C0FC)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          node.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Lettera',
          ),
        ),
      ),
    );
  }
}
```

### 4. Export Graph as JSON

**Scenario:** Save the graph state for later use

```dart
// In concept_cartographer_screen.dart
void _exportGraph() {
  final jsonString = jsonEncode(graphModel.toJson());
  
  // Copy to clipboard
  Clipboard.setData(ClipboardData(text: jsonString));
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Graph exported to clipboard')),
  );
}

void _importGraph(String jsonString) {
  try {
    final json = jsonDecode(jsonString);
    final importedGraph = GraphModel.fromJson(json);
    
    setState(() {
      graphModel = importedGraph;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Graph imported successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error importing graph: $e')),
    );
  }
}
```

### 5. Auto-Layout Nodes

**Scenario:** Automatically arrange nodes in a better layout

```dart
// Force-directed layout
void _autoLayoutGraph() {
  const iterations = 50;
  const repulsionForce = 100.0;
  const attractionForce = 0.1;
  const damping = 0.9;

  // Initialize velocities
  final velocities = <String, Offset>{};
  for (final node in graphModel.nodes) {
    velocities[node.id] = Offset.zero;
  }

  for (int iter = 0; iter < iterations; iter++) {
    for (final node in graphModel.nodes) {
      var fx = 0.0;
      var fy = 0.0;

      // Repulsion from other nodes
      for (final other in graphModel.nodes) {
        if (node.id == other.id) continue;
        
        final dx = node.x - other.x;
        final dy = node.y - other.y;
        final distance = sqrt(dx * dx + dy * dy) + 0.1;
        
        fx += (dx / distance) * repulsionForce;
        fy += (dy / distance) * repulsionForce;
      }

      // Attraction to connected nodes
      for (final edge in graphModel.edges) {
        if (edge.sourceId == node.id) {
          final target = graphModel.getNode(edge.targetId);
          if (target != null) {
            final dx = target.x - node.x;
            final dy = target.y - node.y;
            fx += dx * attractionForce;
            fy += dy * attractionForce;
          }
        }
      }

      // Update velocity
      var vx = (velocities[node.id]?.dx ?? 0) + fx;
      var vy = (velocities[node.id]?.dy ?? 0) + fy;
      vx *= damping;
      vy *= damping;
      velocities[node.id] = Offset(vx, vy);

      // Update position
      graphModel.updateNodePosition(
        node.id,
        node.x + vx,
        node.y + vy,
      );
    }
  }

  setState(() {});
}
```

### 6. Highlight Connected Nodes

**Scenario:** When selecting a node, highlight all connected nodes

```dart
// In graph_canvas_enhanced.dart, modify _handleTapDown()
void _handleTapDown(TapDownDetails details) {
  final tapPos = details.localPosition;

  if (_graph.isDrawingEdge) {
    // ... existing code ...
  } else {
    final tappedNode = _findNodeAtPosition(tapPos);

    if (tappedNode != null) {
      setState(() {
        // Clear previous selections
        _graph.clearSelections();
        
        // Select tapped node
        _graph.toggleNodeSelection(tappedNode.id);
        
        // Highlight connected nodes
        final connectedEdges = _graph.getConnectedEdges(tappedNode.id);
        for (final edge in connectedEdges) {
          final connectedId = edge.sourceId == tappedNode.id 
              ? edge.targetId 
              : edge.sourceId;
          final connectedNode = _graph.getNode(connectedId);
          if (connectedNode != null) {
            // Mark as "related" (could use a separate property)
            connectedNode.color = Color(0xFF74C0FC).withOpacity(0.6);
          }
        }
      });
      widget.onGraphChanged();
    } else {
      setState(() {
        _graph.clearSelections();
      });
      widget.onGraphChanged();
    }
  }
}
```

### 7. Constrain Nodes to Canvas Bounds

**Scenario:** Prevent nodes from being dragged outside the canvas

```dart
// Already implemented in _handlePanUpdate(), but here's the detailed version:
void _handlePanUpdate(DragUpdateDetails details) {
  if (_graph.isDrawingEdge) {
    setState(() {
      _graph.previewEdgeX = details.localPosition.dx;
      _graph.previewEdgeY = details.localPosition.dy;
    });
  } else if (_graph.draggingNodeId != null) {
    final canvasWidth = context.size?.width ?? 400;
    final canvasHeight = context.size?.height ?? 400;
    
    final newX = details.localPosition.dx.clamp(
      _nodeRadius,
      canvasWidth - _nodeRadius,
    );
    final newY = details.localPosition.dy.clamp(
      _nodeRadius,
      canvasHeight - _nodeRadius,
    );

    setState(() {
      _graph.updateNodePosition(_graph.draggingNodeId!, newX, newY);
    });
    widget.onGraphChanged();
  }
}
```

### 8. Show Edge Statistics

**Scenario:** Display count of connections per node

```dart
// In _buildConceptAssemblyPhase(), add after connections list:
if (graphModel.nodes.isNotEmpty) ...[
  SizedBox(height: 24),
  Text(
    'Node Statistics:',
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'Ntype82-R',
    ),
  ),
  SizedBox(height: 12),
  ...graphModel.nodes.map((node) {
    final connectionCount = graphModel.getConnectedEdges(node.id).length;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(node.text, style: Theme.of(context).textTheme.bodySmall),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF74C0FC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$connectionCount connections',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Color(0xFF74C0FC),
              ),
            ),
          ),
        ],
      ),
    );
  }),
],
```

## Performance Tips

1. **Limit nodes to 50** before implementing spatial indexing
2. **Cache TextPainter** instances for node labels
3. **Use `shouldRepaint` wisely** to avoid unnecessary redraws
4. **Profile on real devices** before optimizing further
5. **Consider lazy loading** for very large graphs

## Testing Customizations

```dart
// Test helper
void _testGraphCustomization() {
  // Create test graph
  graphModel.nodes.clear();
  graphModel.edges.clear();

  // Add test nodes
  for (int i = 0; i < 5; i++) {
    graphModel.addNode(GraphNode(
      id: 'test_$i',
      x: 100 + i * 50,
      y: 100,
      text: 'Test Node $i',
    ));
  }

  // Add test edges
  for (int i = 0; i < 4; i++) {
    graphModel.addEdge(GraphEdge(
      id: 'edge_$i',
      sourceId: 'test_$i',
      targetId: 'test_${i + 1}',
      label: 'connects to',
    ));
  }

  setState(() {});
}
```

## Debugging Tips

```dart
// Add logging to track graph state
void _logGraphState() {
  print('Nodes: ${graphModel.nodes.length}');
  print('Edges: ${graphModel.edges.length}');
  print('Drawing edge: ${graphModel.isDrawingEdge}');
  print('Selected nodes: ${graphModel.nodes.where((n) => n.isSelected).length}');
  
  for (final node in graphModel.nodes) {
    final connections = graphModel.getConnectedEdges(node.id);
    print('${node.text}: ${connections.length} connections');
  }
}
```
