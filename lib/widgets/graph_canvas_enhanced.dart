import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/graph_models.dart';
import 'graph_painter.dart';
import 'node_info_modal.dart';

class GraphCanvasEnhanced extends StatefulWidget {
  final GraphModel graph;
  final VoidCallback onGraphChanged;
  final double width;
  final double height;
  final bool showInstructions;

  const GraphCanvasEnhanced({
    Key? key,
    required this.graph,
    required this.onGraphChanged,
    this.width = double.infinity,
    this.height = 400,
    this.showInstructions = true,
  }) : super(key: key);

  @override
  State<GraphCanvasEnhanced> createState() => _GraphCanvasEnhancedState();
}

class _GraphCanvasEnhancedState extends State<GraphCanvasEnhanced>
    with SingleTickerProviderStateMixin {
  late GraphModel _graph;
  bool _showInstructionOverlay = true;
  late AnimationController _pulseController;
  final bool _isMobile = Platform.isAndroid || Platform.isIOS;
  GraphNode? _selectedNodeForInfo;

  // Touch target sizes
  late double _nodeRadius;

  @override
  void initState() {
    super.initState();
    _graph = widget.graph;
    _showInstructionOverlay = widget.showInstructions;

    // Adjust sizes based on platform
    _nodeRadius = _isMobile ? 50.0 : 40.0;

    // Animation for pulsing unconnected nodes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(GraphCanvasEnhanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _graph = widget.graph;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main canvas
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[950],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onLongPress: _handleLongPress,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: CustomPaint(
              painter: GraphPainter(graph: _graph),
              size: Size.infinite,
            ),
          ),
        ),

        // Node info modal
        if (_selectedNodeForInfo != null)
          NodeInfoModal(
            node: _selectedNodeForInfo!,
            onClose: () {
              setState(() {
                _selectedNodeForInfo = null;
              });
            },
          ),

        // Instruction overlay
        if (_showInstructionOverlay)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF74C0FC)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Graph Controls',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Ntype82-R',
                          color: Color(0xFF74C0FC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        Icons.pan_tool,
                        'Drag nodes to arrange them',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionItem(
                        Icons.touch_app,
                        'Tap to select/deselect',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionItem(
                        Icons.link,
                        'Use "Draw Connection" button to create edges',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _showInstructionOverlay = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF74C0FC),
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF74C0FC), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final tapPos = details.localPosition;

    if (_graph.isDrawingEdge) {
      final tappedNode = _findNodeAtPosition(tapPos);

      if (tappedNode == null) return;

      if (_graph.edgeSourceNodeId == null) {
        setState(() {
          _graph.edgeSourceNodeId = tappedNode.id;
        });
      } else if (tappedNode.id == _graph.edgeSourceNodeId) {
        setState(() {
          _graph.edgeSourceNodeId = null;
        });
      } else {
        _showEdgeLabelDialog(tappedNode);
      }
    } else {
      final tappedNode = _findNodeAtPosition(tapPos);

      if (tappedNode != null) {
        // Show node info modal instead of selecting
        setState(() {
          _selectedNodeForInfo = tappedNode;
        });
      } else {
        setState(() {
          _graph.clearSelections();
        });
        widget.onGraphChanged();
      }
    }
  }

  void _handleLongPress() {
    if (_isMobile) {
      final selectedNode = _graph.nodes.firstWhere(
        (n) => n.isSelected,
        orElse: () => GraphNode(id: '', x: 0, y: 0, text: ''),
      );

      if (selectedNode.id.isNotEmpty) {
        _showNodeContextMenu(selectedNode);
      }
    }
  }

  void _showNodeContextMenu(GraphNode node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Label'),
              onTap: () {
                Navigator.pop(context);
                _showEditLabelDialog(node);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _graph.removeNode(node.id);
                });
                widget.onGraphChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLabelDialog(GraphNode node) {
    final controller = TextEditingController(text: node.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Node Label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter node label',
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
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final index = _graph.nodes.indexWhere((n) => n.id == node.id);
                  if (index != -1) {
                    _graph.nodes[index] = _graph.nodes[index].copyWith(
                      text: controller.text.trim(),
                    );
                  }
                });
                widget.onGraphChanged();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
      setState(() {
        _graph.previewEdgeX = details.localPosition.dx;
        _graph.previewEdgeY = details.localPosition.dy;
      });
    } else if (_graph.draggingNodeId != null) {
      final newX = details.localPosition.dx.clamp(
        _nodeRadius,
        context.size?.width ?? 400 - _nodeRadius,
      );
      final newY = details.localPosition.dy.clamp(
        _nodeRadius,
        context.size?.height ?? 400 - _nodeRadius,
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
      final dx = position.dx - node.x;
      final dy = position.dy - node.y;
      final distanceSquared = dx * dx + dy * dy;
      final radiusSquared = _nodeRadius * _nodeRadius;
      if (distanceSquared <= radiusSquared) {
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
    setState(() {
      final selectedNode = _graph.nodes.firstWhere(
        (n) => n.isSelected,
        orElse: () => GraphNode(id: '', x: 0, y: 0, text: ''),
      );

      if (selectedNode.id.isNotEmpty) {
        _graph.removeNode(selectedNode.id);
        return;
      }

      final selectedEdge = _graph.edges.firstWhere(
        (e) => e.isSelected,
        orElse: () => GraphEdge(id: '', sourceId: '', targetId: '', label: ''),
      );

      if (selectedEdge.id.isNotEmpty) {
        _graph.removeEdge(selectedEdge.id);
      }
    });
    widget.onGraphChanged();
  }
}
