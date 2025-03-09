import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:scribble/bloc/drawing_bloc.dart';
import 'package:scribble/bloc/drawing_event.dart';
import 'package:scribble/bloc/drawing_state.dart';

import '../models/drawing.dart';

class DrawingCanvas extends StatefulWidget {
  final bool isDrawingTurn;
  final bool isAiMode;
  final Color backgroundColor;
  final double strokeWidth;
  final Color strokeColor;
  final double canvasWidth;
  final double canvasHeight;

  const DrawingCanvas({
    super.key,
    required this.isDrawingTurn,
    this.isAiMode = false,
    this.backgroundColor = Colors.white,
    this.strokeWidth = 5.0,
    this.strokeColor = Colors.black,
    this.canvasWidth = 800,
    this.canvasHeight = 600,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  void initState() {
    super.initState();

    // Initialize drawing
    context.read<DrawingBloc>().add(
      DrawingStarted(canvasSize: Size(widget.canvasWidth, widget.canvasHeight)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingBloc, DrawingState>(
      builder: (context, state) {
        if (state is! DrawingReady) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Canvas
            Container(
              width: widget.canvasWidth,
              height: widget.canvasHeight,
              decoration: BoxDecoration(
                color: state.drawing.backgroundColor,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Drawing
                    CustomPaint(
                      size: Size(widget.canvasWidth, widget.canvasHeight),
                      painter: DrawingPainter(drawing: state.drawing),
                    ),

                    // Drawing overlay
                    if (widget.isDrawingTurn && !state.isAiGenerating)
                      GestureDetector(
                        onPanStart: (details) {
                          final localPosition = details.localPosition;

                          // Calculate pressure (if available)
                          final pressure = 1.0;

                          // Add event
                          context.read<DrawingBloc>().add(
                            DrawingPointerDown(
                              position: localPosition,
                              pressure: pressure,
                            ),
                          );
                        },
                        onPanUpdate: (details) {
                          final localPosition = details.localPosition;

                          // Calculate pressure (if available)
                          final pressure = 1.0;

                          // Add event
                          context.read<DrawingBloc>().add(
                            DrawingPointerMove(
                              position: localPosition,
                              pressure: pressure,
                            ),
                          );
                        },
                        onPanEnd: (details) {
                          // Add event
                          context.read<DrawingBloc>().add(
                            DrawingPointerUp(
                              position:
                                  Offset.zero, // End position doesn't matter
                            ),
                          );
                        },
                        child: Container(color: Colors.transparent),
                      ),

                    // Loading overlay
                    if (state.isAiGenerating)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'AI is drawing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Not your turn overlay
                    if (!widget.isDrawingTurn && !state.isAiGenerating)
                      Container(color: Colors.transparent),
                  ],
                ),
              ),
            ),

            // Drawing controls
            if (widget.isDrawingTurn && !state.isAiGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Color palette
                    _buildColorButton(context, Colors.black),
                    _buildColorButton(context, Colors.red),
                    _buildColorButton(context, Colors.orange),
                    _buildColorButton(context, Colors.yellow),
                    _buildColorButton(context, Colors.green),
                    _buildColorButton(context, Colors.blue),
                    _buildColorButton(context, Colors.purple),
                    _buildColorButton(context, Colors.brown),

                    const SizedBox(width: 16),

                    // Stroke width
                    Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Slider(
                        value: state.currentStrokeWidth,
                        min: 1.0,
                        max: 20.0,
                        label: state.currentStrokeWidth.toStringAsFixed(1),
                        onChanged: (value) {
                          context.read<DrawingBloc>().add(
                            DrawingStrokeWidthChanged(value),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Clear button
                    IconButton(
                      onPressed: () {
                        context.read<DrawingBloc>().add(DrawingCanvasCleared());
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear Canvas',
                    ),

                    // Undo button
                    IconButton(
                      onPressed: () {
                        context.read<DrawingBloc>().add(
                          DrawingUndoLastStroke(),
                        );
                      },
                      icon: const Icon(Icons.undo),
                      tooltip: 'Undo Last Stroke',
                    ),

                    // AI button (if AI mode enabled)
                    if (widget.isAiMode)
                      IconButton(
                        onPressed: () {
                          // Show dialog to confirm AI drawing
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Use AI to Draw?'),
                                  content: const Text(
                                    'The AI will generate and draw an image based on the current word. '
                                    'This will replace your current drawing. Continue?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        // Trigger AI drawing
                                        // For this mockup, we'll use a fixed word
                                        context.read<DrawingBloc>().add(
                                          const DrawingAiGenerated('cat'),
                                        );
                                      },
                                      child: const Text('Use AI'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: const Icon(Icons.auto_fix_high),
                        tooltip: 'Use AI to Draw',
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(BuildContext context, Color color) {
    return BlocBuilder<DrawingBloc, DrawingState>(
      builder: (context, state) {
        if (state is! DrawingReady) {
          return const SizedBox.shrink();
        }

        final isSelected = state.currentColor.value == color.value;

        return GestureDetector(
          onTap: () {
            context.read<DrawingBloc>().add(DrawingColorChanged(color));
          },
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
          ),
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final Drawing drawing;

  DrawingPainter({required this.drawing});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint =
        Paint()
          ..color = drawing.backgroundColor
          ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw strokes
    for (final stroke in drawing.strokes) {
      if (stroke.points.isEmpty) continue;

      // Use perfect freehand for smooth strokes
      final points =
          stroke.points
              .map(
                (point) =>
                    PointVector(point.point.dx, point.point.dy, point.pressure),
              )
              .toList();

      final outlinePoints = getStroke(
        points,
        options: StrokeOptions(
          size: stroke.strokeWidth,
          thinning: 0.6,
          smoothing: 0.5,
          streamline: 0.5,
          start: StrokeEndOptions.start(cap: true, taperEnabled: false),
          end: StrokeEndOptions.end(cap: true, taperEnabled: false),
          simulatePressure: false,
          isComplete: true,
        ),
      );

      if (outlinePoints.isEmpty) continue;

      final path = Path();

      path.moveTo(
        outlinePoints.first.dx.toDouble(),
        outlinePoints.first.dy.toDouble(),
      );

      for (var i = 1; i < outlinePoints.length; i++) {
        path.lineTo(
          outlinePoints[i].dx.toDouble(),
          outlinePoints[i].dy.toDouble(),
        );
      }

      path.close();

      final paint =
          Paint()
            ..color = stroke.color
            ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.drawing != drawing;
  }
}
