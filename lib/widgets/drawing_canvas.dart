import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final String? currentWord;

  const DrawingCanvas({
    super.key,
    required this.isDrawingTurn,
    this.isAiMode = false,
    this.backgroundColor = Colors.white,
    this.strokeWidth = 5.0,
    this.strokeColor = Colors.black,
    this.canvasWidth = 800,
    this.canvasHeight = 600,
    this.currentWord,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas>
    with SingleTickerProviderStateMixin {
  // Animation controller for visual effects
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  // Confetti controller for correct guess celebrations
  late ConfettiController _confettiController;

  // Selected tool
  DrawingTool _selectedTool = DrawingTool.pen;

  // Recent colors for quick selection
  final List<Color> _recentColors = [];

  // Predefined color palette - updated with more playful colors
  final List<Color> _colorPalette = [
    Colors.black,
    Colors.white,
    const Color(0xFFFF6B6B), // Red
    const Color(0xFFFF9E4A), // Orange
    const Color(0xFFFFE66D), // Yellow
    const Color(0xFF7EC636), // Green
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF6B9DFF), // Blue
    const Color(0xFF9B6BFF), // Purple
    const Color(0xFFFF6BCB), // Pink
    const Color(0xFF8B572A), // Brown
    const Color(0xFF666666), // Gray
  ];

  // Additional controls state
  bool _showControls = true;
  bool _isColorPickerOpen = false;
  bool _showGuideLines = false;

  // For eraser preview
  Offset? _currentPosition;

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
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _addRecentColor(Color color) {
    // Don't add if it's already the most recent
    if (_recentColors.isNotEmpty && _recentColors.first == color) {
      return;
    }

    setState(() {
      // Remove the color if it exists elsewhere in the list
      _recentColors.remove(color);
      // Add to the beginning
      _recentColors.insert(0, color);
      // Keep only the last 5 colors
      if (_recentColors.length > 5) {
        _recentColors.removeLast();
      }
    });
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
            // Word hint for drawer
            if (widget.isDrawingTurn && widget.currentWord != null)
              _buildWordBanner(widget.currentWord!),

            // Confetti at the top of canvas
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                shouldLoop: false,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                  AppTheme.accentColor,
                  AppTheme.warningColor,
                  AppTheme.tertiaryColor,
                ],
              ),
            ),

            // Canvas container with animations and effects
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: widget.canvasWidth,
                height: widget.canvasHeight,
                decoration: BoxDecoration(
                  color: state.drawing.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.mediumShadow,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Grid background for better drawing reference
                      if (_showGuideLines) _buildGridBackground(),

                      // Drawing
                      CustomPaint(
                        size: Size(widget.canvasWidth, widget.canvasHeight),
                        painter: EnhancedDrawingPainter(
                          drawing: state.drawing,
                          showGuideLines: _showGuideLines,
                        ),
                      ),

                      // Drawing overlay for handling gestures
                      if (widget.isDrawingTurn && !state.isAiGenerating)
                        GestureDetector(
                          onPanStart: (details) {
                            final localPosition = details.localPosition;
                            final pressure = 1.0;

                            setState(() {
                              _currentPosition = localPosition;
                            });

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

                            setState(() {
                              _currentPosition = localPosition;
                            });

                            // Add event
                            context.read<DrawingBloc>().add(
                              DrawingPointerMove(
                                position: localPosition,
                                pressure: pressure,
                              ),
                            );
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _currentPosition = null;
                            });

                            // Add event
                            context.read<DrawingBloc>().add(
                              DrawingPointerUp(
                                position:
                                    Offset.zero, // End position doesn't matter
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(color: Colors.transparent),

                              // Eraser preview (only show for eraser tool)
                              if (_selectedTool == DrawingTool.eraser &&
                                  _currentPosition != null)
                                Positioned(
                                  left:
                                      _currentPosition!.dx -
                                      state.currentStrokeWidth / 2,
                                  top:
                                      _currentPosition!.dy -
                                      state.currentStrokeWidth / 2,
                                  child: Container(
                                    width: state.currentStrokeWidth,
                                    height: state.currentStrokeWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Loading overlay with animation
                      if (state.isAiGenerating)
                        Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated AI icon
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 6.28),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentColor
                                                  .withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.auto_fix_high,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                  onEnd:
                                      () => setState(
                                        () {},
                                      ), // Trigger rebuild to continue animation
                                ),

                                const SizedBox(height: 32),

                                // AI drawing text
                                Text(
                                  'AI is drawing...',
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Progress indicator
                                SizedBox(
                                  width: 240,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.white24,
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 8,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Fun message
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '✨ Creating a masterpiece! ✨',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showControls = !_showControls;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
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
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Drawing controls with animations
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height:
                  _showControls && widget.isDrawingTurn && !state.isAiGenerating
                      ? null
                      : 0,
              curve: Curves.easeInOut,
              child:
                  _showControls && widget.isDrawingTurn && !state.isAiGenerating
                      ? _buildDrawingControls(context, state)
                      : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWordBanner(String word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.brush, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'Draw: $word',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size(widget.canvasWidth, widget.canvasHeight),
      painter: GridPainter(
        gridSize: 20,
        gridColor: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildDrawingControls(BuildContext context, DrawingReady state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                                : AppTheme.coloredShadow(state.currentColor),
                      ),
                      child: Center(
                        child:
                            _isColorPickerOpen
                                ? const Icon(Icons.close, color: Colors.white)
                                : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Drawing tools - updated with more playful design
                  _buildToolButton(DrawingTool.pen, Icons.edit, 'Pen', state),
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
                  _buildActionButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      context.read<DrawingBloc>().add(DrawingUndoLastStroke());
                    },
                  ),

                  // Clear button
                  _buildActionButton(
                    icon: Icons.clear,
                    tooltip: 'Clear Canvas',
                    color: AppTheme.errorColor,
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                'Clear Canvas?',
                                style: GoogleFonts.fredoka(),
                              ),
                              content: const Text(
                                'This will erase your entire drawing. Are you sure?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    context.read<DrawingBloc>().add(
                                      DrawingCanvasCleared(),
                                    );

                                    // Trigger confetti for fun
                                    _confettiController.play();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),

                  // Grid toggle button
                  _buildActionButton(
                    icon: Icons.grid_on,
                    tooltip: 'Toggle Grid',
                    color:
                        _showGuideLines ? AppTheme.primaryColor : Colors.grey,
                    onPressed: () {
                      setState(() {
                        _showGuideLines = !_showGuideLines;
                      });
                    },
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
                                  title: Text(
                                    'Use AI to Draw?',
                                    style: GoogleFonts.fredoka(),
                                  ),
                                  content: const Text(
                                    'The AI will generate and draw an image based on the current word. '
                                    'This will replace your current drawing. Continue?',
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

                                        // Use the current word if provided
                                        final wordToUse =
                                            widget.currentWord ?? 'doodle';

                                        context.read<DrawingBloc>().add(
                                          DrawingAiGenerated(wordToUse),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentColor,
                                        foregroundColor: Colors.black,
                                      ),
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

              // Recently used colors
              if (_recentColors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Recent: ', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      ...List.generate(
                        _recentColors.length,
                        (index) => _buildColorButton(
                          context,
                          _recentColors[index],
                          state,
                          size: 24,
                          margin: 4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Color picker (when open)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isColorPickerOpen ? null : 0,
                curve: Curves.easeInOut,
                child:
                    _isColorPickerOpen
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 8.0,
                                top: 12.0,
                                bottom: 8.0,
                              ),
                              child: Text(
                                'Basic Colors',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Center(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._colorPalette.map(
                                    (color) => _buildColorButton(
                                      context,
                                      color,
                                      state,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              // Divider
              if (_isColorPickerOpen) const Divider(height: 24),

              // Stroke width slider with live preview
              Row(
                children: [
                  const Icon(Icons.line_weight, size: 20),
                  Expanded(
                    child: Slider(
                      value: state.currentStrokeWidth,
                      min: 1.0,
                      max: 30.0,
                      divisions: 29,
                      label: state.currentStrokeWidth.toStringAsFixed(1),
                      onChanged: (value) {
                        context.read<DrawingBloc>().add(
                          DrawingStrokeWidthChanged(value),
                        );
                      },
                    ),
                  ),
                  // Width preview
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Container(
                        width: state.currentStrokeWidth,
                        height: state.currentStrokeWidth,
                        decoration: BoxDecoration(
                          color: state.currentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected ? AppTheme.smallShadow : null,
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

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }

  Widget _buildColorButton(
    BuildContext context,
    Color color,
    DrawingReady state, {
    double size = 36,
    double margin = 0,
  }) {
    final isSelected = state.currentColor.value == color.value;
    final borderColor = color == Colors.white ? Colors.grey.shade300 : color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.all(margin),
      child: GestureDetector(
        onTap: () {
          // Reset to previous tool if coming from eraser
          if (_selectedTool == DrawingTool.eraser) {
            setState(() {
              _selectedTool = DrawingTool.pen;
            });
          }

          context.read<DrawingBloc>().add(DrawingColorChanged(color));
          _addRecentColor(color);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isSelected
                      ? AppTheme.primaryColor
                      : borderColor.withOpacity(0.5),
              width: isSelected ? 3 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child:
              isSelected
                  ? const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

// Improved Drawing Tool enum
enum DrawingTool { pen, marker, highlighter, eraser }

// Enhanced Drawing Painter with smoother rendering
class EnhancedDrawingPainter extends CustomPainter {
  final Drawing drawing;
  final bool showGuideLines;

  EnhancedDrawingPainter({required this.drawing, this.showGuideLines = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint =
        Paint()
          ..color = drawing.backgroundColor
          ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw strokes with perfect freehand for smoother rendering
    for (final stroke in drawing.strokes) {
      if (stroke.points.isEmpty) continue;

      // Convert DrawPoint to PointVector for perfect freehand
      final points =
          stroke.points
              .map(
                (point) =>
                    PointVector(point.point.dx, point.point.dy, point.pressure),
              )
              .toList();

      // Create smooth stroke with perfect freehand
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
  bool shouldRepaint(covariant EnhancedDrawingPainter oldDelegate) {
    return oldDelegate.drawing != drawing ||
        oldDelegate.showGuideLines != showGuideLines;
  }
}

// Grid Painter for guide lines
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  GridPainter({this.gridSize = 20, this.gridColor = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Don't forget to add confetti package to pubspec.yaml:
// dependencies:
//   confetti: ^0.7.0
