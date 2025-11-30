import 'dart:math';
import 'package:flutter/material.dart';
import '../models/graph_models.dart';

class GraphPainter extends CustomPainter {
  final GraphModel graph;
  final Color edgeColor;
  final Color selectedEdgeColor;
  final Color nodeColor;
  final Color selectedNodeColor;
  final TextStyle textStyle;

  GraphPainter({
    required this.graph,
    this.edgeColor = const Color(0xFF74C0FC),
    this.selectedEdgeColor = const Color(0xFFFF6B6B),
    this.nodeColor = const Color(0xFF74C0FC),
    this.selectedNodeColor = const Color(0xFFFFD93D),
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontFamily: 'Lettera',
    ),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges first (so they appear behind nodes)
    _drawEdges(canvas, size);

    // Draw preview edge if in drawing mode
    if (graph.isDrawingEdge &&
        graph.edgeSourceNodeId != null &&
        graph.previewEdgeX != null &&
        graph.previewEdgeY != null) {
      _drawPreviewEdge(canvas);
    }

    // Draw nodes on top
    _drawNodes(canvas, size);
  }

  void _drawEdges(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final sourceNode = graph.getNode(edge.sourceId);
      final targetNode = graph.getNode(edge.targetId);

      if (sourceNode == null || targetNode == null) continue;

      // Draw edge line
      final edgePaint = Paint()
        ..color = edge.isSelected ? selectedEdgeColor : edgeColor
        ..strokeWidth = edge.isSelected ? 3.0 : 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(sourceNode.x, sourceNode.y),
        Offset(targetNode.x, targetNode.y),
        edgePaint,
      );

      // Draw arrowhead using cached angle
      _drawArrowhead(canvas, sourceNode, targetNode, edgePaint, edge);

      // Draw edge label
      _drawEdgeLabel(canvas, sourceNode, targetNode, edge.label);
    }
  }

  void _drawPreviewEdge(Canvas canvas) {
    final sourceNode = graph.getNode(graph.edgeSourceNodeId!);
    if (sourceNode == null) return;

    final paint = Paint()
      ..color = edgeColor.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw dotted line
    _drawDottedLine(
      canvas,
      Offset(sourceNode.x, sourceNode.y),
      Offset(graph.previewEdgeX!, graph.previewEdgeY!),
      paint,
    );
  }

  void _drawArrowhead(
    Canvas canvas,
    GraphNode source,
    GraphNode target,
    Paint paint,
    GraphEdge edge,
  ) {
    const arrowSize = 15.0;
    const arrowAngle = pi / 6; // 30 degrees

    final angle = edge.getAngle(source.x, source.y, target.x, target.y);

    // Calculate arrowhead position (at target node edge)
    final arrowX = target.x - GraphNode.radius * cos(angle);
    final arrowY = target.y - GraphNode.radius * sin(angle);

    // Calculate arrowhead points
    final point1X = arrowX - arrowSize * cos(angle - arrowAngle);
    final point1Y = arrowY - arrowSize * sin(angle - arrowAngle);
    final point2X = arrowX - arrowSize * cos(angle + arrowAngle);
    final point2Y = arrowY - arrowSize * sin(angle + arrowAngle);

    // Draw arrowhead triangle
    final path = Path()
      ..moveTo(arrowX, arrowY)
      ..lineTo(point1X, point1Y)
      ..lineTo(point2X, point2Y)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _drawEdgeLabel(
    Canvas canvas,
    GraphNode source,
    GraphNode target,
    String label,
  ) {
    if (label.isEmpty) return;

    // Calculate midpoint
    final midX = (source.x + target.x) / 2;
    final midY = (source.y + target.y) / 2;

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background rectangle
    const padding = 4.0;
    final rect = Rect.fromLTWH(
      midX - textPainter.width / 2 - padding,
      midY - textPainter.height / 2 - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );

    final bgPaint = Paint()
      ..color = Colors.grey[900]!.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      bgPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
    );
  }

  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final steps = (distance / (dashWidth + dashSpace)).ceil();

    for (int i = 0; i < steps; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / distance;
      final t2 = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;

      if (t1 < 1.0) {
        canvas.drawLine(
          Offset(
            start.dx + dx * t1.clamp(0.0, 1.0),
            start.dy + dy * t1.clamp(0.0, 1.0),
          ),
          Offset(
            start.dx + dx * t2.clamp(0.0, 1.0),
            start.dy + dy * t2.clamp(0.0, 1.0),
          ),
          paint,
        );
      }
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    for (final node in graph.nodes) {
      // Draw node circle
      final nodePaint = Paint()
        ..color = node.isSelected ? selectedNodeColor : nodeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(node.x, node.y), GraphNode.radius, nodePaint);

      // Draw border if selected
      if (node.isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(
          Offset(node.x, node.y),
          GraphNode.radius,
          borderPaint,
        );
      }

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: GraphNode.radius * 1.8);

      textPainter.paint(
        canvas,
        Offset(node.x - textPainter.width / 2, node.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return oldDelegate.graph != graph;
  }
}
