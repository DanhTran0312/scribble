import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/drawing.dart';

class LineTracingService {
  final Random _random = Random();

  // In a real app, this would perform image processing to trace lines in the image
  // For our mockup, we'll simulate this with random strokes
  Future<List<DrawStroke>> traceImage(String imageUrl) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 1));

    // Generate random strokes to simulate tracing
    return _generateRandomStrokes();
  }

  List<DrawStroke> _generateRandomStrokes() {
    // Number of strokes to generate
    final int strokeCount = 10 + _random.nextInt(20);

    // Canvas size
    const width = 400.0;
    const height = 300.0;

    // List to hold generated strokes
    final List<DrawStroke> strokes = [];

    // Generate random strokes
    for (int i = 0; i < strokeCount; i++) {
      // Generate a random starting point
      final startX = _random.nextDouble() * width;
      final startY = _random.nextDouble() * height;

      // Number of points in this stroke
      final pointCount = 3 + _random.nextInt(10);

      // List to hold points for this stroke
      final List<DrawPoint> points = [];

      // Add the starting point
      points.add(
        DrawPoint(
          point: Offset(startX, startY),
          pressure: 0.5 + _random.nextDouble() * 0.5,
          size: 2.0 + _random.nextDouble() * 3.0,
        ),
      );

      // Generate subsequent points with small deviations
      double lastX = startX;
      double lastY = startY;

      for (int j = 1; j < pointCount; j++) {
        // Calculate next point with a random deviation
        final deviation = 5.0 + _random.nextDouble() * 20.0;
        final angle = _random.nextDouble() * 2 * pi;

        final nextX = lastX + cos(angle) * deviation;
        final nextY = lastY + sin(angle) * deviation;

        // Keep points within canvas bounds
        final boundedX = nextX.clamp(0.0, width);
        final boundedY = nextY.clamp(0.0, height);

        // Add the point
        points.add(
          DrawPoint(
            point: Offset(boundedX, boundedY),
            pressure: 0.5 + _random.nextDouble() * 0.5,
            size: 2.0 + _random.nextDouble() * 3.0,
          ),
        );

        // Update last position
        lastX = boundedX;
        lastY = boundedY;
      }

      // Create a stroke with random color (mostly blacks and grays for doodle-like effect)
      final grayscale = (50 + _random.nextInt(150)).toDouble();
      final color = Color.fromRGBO(
        grayscale.toInt(),
        grayscale.toInt(),
        grayscale.toInt(),
        1.0,
      );

      final stroke = DrawStroke(
        points: points,
        color: color,
        strokeWidth: 2.0 + _random.nextDouble() * 3.0,
      );

      strokes.add(stroke);
    }

    return strokes;
  }
}
