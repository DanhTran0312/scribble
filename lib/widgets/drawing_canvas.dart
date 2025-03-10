import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../bloc/drawing_bloc.dart';
import '../bloc/drawing_event.dart';
import '../bloc/drawing_state.dart';
import '../models/drawing.dart';
import '../theme/app_theme.dart';

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

class _DrawingCanvasState extends State<DrawingCanvas>
    with SingleTickerProviderStateMixin {
  // Animation controller for visual effects
  late AnimationController _controller;

  // Selected tool
  DrawingTool _selectedTool = DrawingTool.pen;

  // Predefined color palette
  final List<Color> _colorPalette = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.brown,
    Colors.grey,
  ];

  // Additional controls state
  bool _showControls = true;
  bool _isColorPickerOpen = false;

  @override
  void initState() {
    super.initState();

    // Initialize drawing
    context.read<DrawingBloc>().add(
      DrawingStarted(canvasSize: Size(widget.canvasWidth, widget.canvasHeight)),
    );

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            // Canvas container with drop shadow
            Container(
              width: widget.canvasWidth,
              height: widget.canvasHeight,
              decoration: BoxDecoration(
                color: state.drawing.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.mediumShadow,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated AI icon
                              AnimatedBuilder(
                                animation: _controller..repeat(),
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _controller.value * 2 * 3.14159,
                                    child: const Icon(
                                      Icons.auto_fix_high,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // AI drawing text
                              const Text(
                                'AI is drawing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Progress indicator
                              SizedBox(
                                width: 200,
                                child: const LinearProgressIndicator(
                                  backgroundColor: Colors.white24,
                                  color: AppTheme.accentColor,
                                ),
                              ),

                              const SizedBox(height: 24),

                              const Text(
                                'Creating a masterpiece!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Not your turn overlay
                    if (!widget.isDrawingTurn && !state.isAiGenerating)
                      Container(color: Colors.transparent),

                    // Mini toolbar toggle
                    if (widget.isDrawingTurn && !state.isAiGenerating)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showControls = !_showControls;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.smallShadow,
                            ),
                            child: Icon(
                              _showControls
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Drawing controls
            if (widget.isDrawingTurn && !state.isAiGenerating && _showControls)
              AnimatedContainer(
                duration: AppTheme.shortAnimationDuration,
                height: _showControls ? null : 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      // Color and tool selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Current color indicator and picker toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isColorPickerOpen = !_isColorPickerOpen;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: state.currentColor,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow:
                                    state.currentColor == Colors.white
                                        ? [
                                          BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                              child:
                                  _isColorPickerOpen
                                      ? const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Drawing tools
                          _buildToolButton(
                            DrawingTool.pen,
                            Icons.edit,
                            'Pen',
                            state,
                          ),
                          _buildToolButton(
                            DrawingTool.marker,
                            Icons.brush,
                            'Marker',
                            state,
                          ),
                          _buildToolButton(
                            DrawingTool.highlighter,
                            Icons.highlight,
                            'Highlighter',
                            state,
                          ),
                          _buildToolButton(
                            DrawingTool.eraser,
                            Icons.auto_fix_normal,
                            'Eraser',
                            state,
                          ),

                          const SizedBox(width: 12),

                          // Undo button
                          IconButton(
                            onPressed: () {
                              context.read<DrawingBloc>().add(
                                DrawingUndoLastStroke(),
                              );
                            },
                            icon: const Icon(Icons.undo),
                            tooltip: 'Undo',
                            color: AppTheme.primaryColor,
                          ),

                          // Clear button
                          IconButton(
                            onPressed: () {
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Clear Canvas?'),
                                      content: const Text(
                                        'This will erase your entire drawing. Are you sure?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            context.read<DrawingBloc>().add(
                                              DrawingCanvasCleared(),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.errorColor,
                                          ),
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear Canvas',
                            color: AppTheme.errorColor,
                          ),

                          // AI button (if AI mode enabled)
                          if (widget.isAiMode)
                            Tooltip(
                              message: 'Use AI to Draw',
                              child: ElevatedButton.icon(
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
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();

                                                // Get the current word from the game state
                                                // For this mockup, we'll use a fixed word
                                                context.read<DrawingBloc>().add(
                                                  const DrawingAiGenerated(
                                                    'cat',
                                                  ),
                                                );
                                              },
                                              style:
                                                  AppTheme.secondaryButtonStyle,
                                              child: const Text('Use AI'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                icon: const Icon(Icons.auto_fix_high),
                                label: const Text('AI Draw'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Color picker (when open)
                      if (_isColorPickerOpen)
                        AnimatedContainer(
                          duration: AppTheme.shortAnimationDuration,
                          height: _isColorPickerOpen ? 70 : 0,
                          margin: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._colorPalette.map(
                                  (color) =>
                                      _buildColorButton(context, color, state),
                                ),
                                // White color
                                _buildColorButton(context, Colors.white, state),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Stroke width slider
                      Row(
                        children: [
                          const Icon(Icons.line_weight, size: 20),
                          Expanded(
                            child: Slider(
                              value: state.currentStrokeWidth,
                              min: 1.0,
                              max: 30.0,
                              divisions: 29,
                              label: state.currentStrokeWidth.toStringAsFixed(
                                1,
                              ),
                              onChanged: (value) {
                                context.read<DrawingBloc>().add(
                                  DrawingStrokeWidthChanged(value),
                                );
                              },
                            ),
                          ),
                          // Width preview
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: Container(
                              width: state.currentStrokeWidth,
                              height: state.currentStrokeWidth,
                              decoration: BoxDecoration(
                                color: state.currentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolButton(
    DrawingTool tool,
    IconData icon,
    String tooltip,
    DrawingReady state,
  ) {
    final isSelected = _selectedTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTool = tool;
          });

          // Apply tool-specific settings
          switch (tool) {
            case DrawingTool.pen:
              context.read<DrawingBloc>().add(DrawingStrokeWidthChanged(3.0));
              break;
            case DrawingTool.marker:
              context.read<DrawingBloc>().add(DrawingStrokeWidthChanged(8.0));
              break;
            case DrawingTool.highlighter:
              context.read<DrawingBloc>().add(DrawingStrokeWidthChanged(15.0));
              // Set semi-transparent color
              final currentColor = state.currentColor;
              context.read<DrawingBloc>().add(
                DrawingColorChanged(currentColor.withOpacity(0.4)),
              );
              break;
            case DrawingTool.eraser:
              context.read<DrawingBloc>().add(
                DrawingColorChanged(Colors.white),
              );
              context.read<DrawingBloc>().add(DrawingStrokeWidthChanged(20.0));
              break;
          }
        },
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(
    BuildContext context,
    Color color,
    DrawingReady state,
  ) {
    final isSelected = state.currentColor.value == color.value;

    return GestureDetector(
      onTap: () {
        // Reset to previous tool if coming from eraser
        if (_selectedTool == DrawingTool.eraser) {
          setState(() {
            _selectedTool = DrawingTool.pen;
          });
        }

        context.read<DrawingBloc>().add(DrawingColorChanged(color));
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }
}

enum DrawingTool { pen, marker, highlighter, eraser }

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
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
          start: StrokeEndOptions.start(customTaper: 0, cap: true),
          end: StrokeEndOptions.end(customTaper: 0, cap: true),
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
