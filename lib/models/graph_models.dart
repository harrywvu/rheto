import 'dart:math';
import 'package:flutter/material.dart';

/// Represents a single node in the concept graph
class GraphNode {
  final String id;
  double x;
  double y;
  final String text;
  final String description;
  final Color color;
  bool isSelected;
  static const double radius = 40.0;

  GraphNode({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    this.description = '',
    this.color = const Color(0xFF74C0FC),
    this.isSelected = false,
  });

  /// Check if a point is inside this node's circle
  bool contains(double px, double py) {
    final dx = px - x;
    final dy = py - y;
    final distanceSquared = dx * dx + dy * dy;
    final radiusSquared = radius * radius;
    return distanceSquared <= radiusSquared;
  }

  /// Create a copy with modified fields
  GraphNode copyWith({
    String? id,
    double? x,
    double? y,
    String? text,
    String? description,
    Color? color,
    bool? isSelected,
  }) {
    return GraphNode(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      description: description ?? this.description,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'text': text,
    'description': description,
    'color': color.value,
  };

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      text: json['text'] as String,
      description: json['description'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF74C0FC),
    );
  }
}

/// Represents an edge (connection) between two nodes
class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String label;
  bool isSelected;

  // Cached values for performance
  double? _cachedAngle;
  double? _cachedLength;

  GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.label,
    this.isSelected = false,
  });

  /// Calculate and cache edge angle (in radians)
  double getAngle(
    double sourceX,
    double sourceY,
    double targetX,
    double targetY,
  ) {
    if (_cachedAngle == null) {
      final dx = targetX - sourceX;
      final dy = targetY - sourceY;
      _cachedAngle = atan2(dy, dx);
    }
    return _cachedAngle!;
  }

  /// Calculate and cache edge length
  double getLength(
    double sourceX,
    double sourceY,
    double targetX,
    double targetY,
  ) {
    if (_cachedLength == null) {
      final dx = targetX - sourceX;
      final dy = targetY - sourceY;
      _cachedLength = sqrt(dx * dx + dy * dy);
    }
    return _cachedLength!;
  }

  /// Invalidate cache when edge is modified
  void invalidateCache() {
    _cachedAngle = null;
    _cachedLength = null;
  }

  /// Create a copy with modified fields
  GraphEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    String? label,
    bool? isSelected,
  }) {
    return GraphEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'targetId': targetId,
    'label': label,
  };

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      label: json['label'] as String,
    );
  }
}

/// Container for the entire graph model
class GraphModel {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  String? draggingNodeId;
  String? edgeSourceNodeId;
  double? previewEdgeX;
  double? previewEdgeY;
  bool isDrawingEdge;

  GraphModel({
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    this.draggingNodeId,
    this.edgeSourceNodeId,
    this.previewEdgeX,
    this.previewEdgeY,
    this.isDrawingEdge = false,
  }) : nodes = nodes ?? [],
       edges = edges ?? [];

  /// Get node by ID
  GraphNode? getNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get edge by ID
  GraphEdge? getEdge(String id) {
    try {
      return edges.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new node
  void addNode(GraphNode node) {
    nodes.add(node);
  }

  /// Update node position
  void updateNodePosition(String nodeId, double x, double y) {
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(x: x, y: y);
    }
  }

  /// Add a new edge
  void addEdge(GraphEdge edge) {
    edges.add(edge);
  }

  /// Remove node and all connected edges
  void removeNode(String nodeId) {
    nodes.removeWhere((n) => n.id == nodeId);
    edges.removeWhere((e) => e.sourceId == nodeId || e.targetId == nodeId);
  }

  /// Remove edge
  void removeEdge(String edgeId) {
    edges.removeWhere((e) => e.id == edgeId);
  }

  /// Toggle node selection
  void toggleNodeSelection(String nodeId) {
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(
        isSelected: !nodes[index].isSelected,
      );
    }
  }

  /// Clear all selections
  void clearSelections() {
    for (int i = 0; i < nodes.length; i++) {
      nodes[i] = nodes[i].copyWith(isSelected: false);
    }
    for (int i = 0; i < edges.length; i++) {
      edges[i] = edges[i].copyWith(isSelected: false);
    }
  }

  /// Get all edges connected to a node
  List<GraphEdge> getConnectedEdges(String nodeId) {
    return edges
        .where((e) => e.sourceId == nodeId || e.targetId == nodeId)
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  factory GraphModel.fromJson(Map<String, dynamic> json) {
    final nodesList =
        (json['nodes'] as List?)
            ?.map((n) => GraphNode.fromJson(n as Map<String, dynamic>))
            .toList() ??
        [];
    final edgesList =
        (json['edges'] as List?)
            ?.map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return GraphModel(nodes: nodesList, edges: edgesList);
  }
}
