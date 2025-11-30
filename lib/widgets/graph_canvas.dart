import 'package:flutter/material.dart';
import '../models/graph_models.dart';
import 'graph_painter.dart';

class GraphCanvas extends StatefulWidget {
  final GraphModel graph;
  final VoidCallback onGraphChanged;
  final double width;
  final double height;

  const GraphCanvas({
    Key? key,
    required this.graph,
    required this.onGraphChanged,
    this.width = double.infinity,
    this.height = 400,
  }) : super(key: key);

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late GraphModel _graph;

  @override
  void initState() {
    super.initState();
    _graph = widget.graph;
  }

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _graph = widget.graph;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[950],
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: CustomPaint(
          painter: GraphPainter(graph: _graph),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final tapPos = details.localPosition;

    if (_graph.isDrawingEdge) {
      // In edge drawing mode
      final tappedNode = _findNodeAtPosition(tapPos);

      if (tappedNode == null) return;

      if (_graph.edgeSourceNodeId == null) {
        // Select source node
        setState(() {
          _graph.edgeSourceNodeId = tappedNode.id;
        });
      } else if (tappedNode.id == _graph.edgeSourceNodeId) {
        // Deselect source node
        setState(() {
          _graph.edgeSourceNodeId = null;
        });
      } else {
        // Select target node and create edge
        _showEdgeLabelDialog(tappedNode);
      }
    } else {
      // Normal mode - toggle node selection
      final tappedNode = _findNodeAtPosition(tapPos);

      if (tappedNode != null) {
        setState(() {
          _graph.toggleNodeSelection(tappedNode.id);
        });
        widget.onGraphChanged();
      } else {
        // Tap on empty space - clear selections
        setState(() {
          _graph.clearSelections();
        });
        widget.onGraphChanged();
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_graph.isDrawingEdge) return;

    final tapPos = details.localPosition;
    final node = _findNodeAtPosition(tapPos);

    if (node != null) {
      setState(() {
        _graph.draggingNodeId = node.id;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_graph.isDrawingEdge) {
      // Update preview edge position
      setState(() {
        _graph.previewEdgeX = details.localPosition.dx;
        _graph.previewEdgeY = details.localPosition.dy;
      });
    } else if (_graph.draggingNodeId != null) {
      // Update node position
      final newX = details.localPosition.dx.clamp(
        GraphNode.radius,
        context.size?.width ?? 400 - GraphNode.radius,
      );
      final newY = details.localPosition.dy.clamp(
        GraphNode.radius,
        context.size?.height ?? 400 - GraphNode.radius,
      );

      setState(() {
        _graph.updateNodePosition(_graph.draggingNodeId!, newX, newY);
      });
      widget.onGraphChanged();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _graph.draggingNodeId = null;
      _graph.previewEdgeX = null;
      _graph.previewEdgeY = null;
    });
  }

  GraphNode? _findNodeAtPosition(Offset position) {
    for (final node in _graph.nodes) {
      if (node.contains(position.dx, position.dy)) {
        return node;
      }
    }
    return null;
  }

  void _showEdgeLabelDialog(GraphNode targetNode) {
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe the relationship'),
        content: TextField(
          controller: labelController,
          decoration: InputDecoration(
            hintText: 'e.g., causes, requires, leads to, enables...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (labelController.text.trim().isNotEmpty) {
                _createEdge(targetNode, labelController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createEdge(GraphNode targetNode, String label) {
    final sourceId = _graph.edgeSourceNodeId;
    if (sourceId == null || sourceId == targetNode.id) return;

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

  void toggleEdgeDrawingMode() {
    setState(() {
      _graph.isDrawingEdge = !_graph.isDrawingEdge;
      if (!_graph.isDrawingEdge) {
        _graph.edgeSourceNodeId = null;
        _graph.previewEdgeX = null;
        _graph.previewEdgeY = null;
      }
    });
  }

  void deleteSelected() {
    final selectedNode = _graph.nodes.firstWhere(
      (n) => n.isSelected,
      orElse: () => GraphNode(id: '', x: 0, y: 0, text: ''),
    );

    if (selectedNode.id.isNotEmpty) {
      setState(() {
        _graph.removeNode(selectedNode.id);
      });
      widget.onGraphChanged();
      return;
    }

    final selectedEdge = _graph.edges.firstWhere(
      (e) => e.isSelected,
      orElse: () => GraphEdge(id: '', sourceId: '', targetId: '', label: ''),
    );

    if (selectedEdge.id.isNotEmpty) {
      setState(() {
        _graph.removeEdge(selectedEdge.id);
      });
      widget.onGraphChanged();
    }
  }
}
