import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/drawing_bloc.dart';
import '../bloc/drawing_event.dart';
import '../bloc/drawing_state.dart';
import '../theme/app_theme.dart';

class AiDrawingControls extends StatefulWidget {
  final String currentWord;

  const AiDrawingControls({super.key, required this.currentWord});

  @override
  State<AiDrawingControls> createState() => _AiDrawingControlsState();
}

class _AiDrawingControlsState extends State<AiDrawingControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  String _selectedStyle = 'doodle';

  final List<AiDrawingStyle> _styles = [
    AiDrawingStyle(
      id: 'doodle',
      name: 'Doodle',
      description: 'Simple hand-drawn style',
      icon: Icons.edit,
    ),
    AiDrawingStyle(
      id: 'sketch',
      name: 'Sketch',
      description: 'Pencil sketch style',
      icon: Icons.create,
    ),
    AiDrawingStyle(
      id: 'cartoon',
      name: 'Cartoon',
      description: 'Fun cartoon style',
      icon: Icons.brush,
    ),
    AiDrawingStyle(
      id: 'pixel',
      name: 'Pixel Art',
      description: 'Retro pixel art style',
      icon: Icons.grid_on,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
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
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with magic wand icon
                  Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        color: AppTheme.accentColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Drawing Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Let AI draw "${widget.currentWord}" for you',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey.shade300),

                  const SizedBox(height: 8),

                  // Style selection label
                  Text(
                    'Choose Drawing Style:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Style selection grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _styles.length,
                    itemBuilder: (context, index) {
                      final style = _styles[index];
                      final isSelected = style.id == _selectedStyle;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStyle = style.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                style.icon,
                                color:
                                    isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      style.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      style.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showConfirmationDialog();
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Generate AI Drawing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Disclaimer
                  Text(
                    'AI-generated drawings may vary in quality and accuracy. The result will replace your current drawing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm AI Drawing'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to use AI to draw "${widget.currentWord}"?',
                ),
                const SizedBox(height: 12),
                Text(
                  'Style: ${_styles.firstWhere((s) => s.id == _selectedStyle).name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will replace your current drawing completely.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
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
                  // Close dialogs
                  Navigator.of(context).pop(); // Close confirmation
                  Navigator.of(context).pop(); // Close AI controls

                  // Generate AI drawing
                  context.read<DrawingBloc>().add(
                    DrawingAiGenerated(
                      widget.currentWord,
                      style: _selectedStyle,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Generate Drawing'),
              ),
            ],
          ),
    );
  }
}

class AiDrawingStyle {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  AiDrawingStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
