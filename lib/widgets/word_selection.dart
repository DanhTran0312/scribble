import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_theme.dart';

class WordSelectionWidget extends StatefulWidget {
  final List<String> wordChoices;
  final Function(String) onWordSelected;
  final int selectionTimeSeconds;

  const WordSelectionWidget({
    super.key,
    required this.wordChoices,
    required this.onWordSelected,
    this.selectionTimeSeconds = 15,
  });

  @override
  State<WordSelectionWidget> createState() => _WordSelectionWidgetState();
}

class _WordSelectionWidgetState extends State<WordSelectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  int _remainingSeconds = 0;
  Timer? _timer;
  int? _hoveredWordIndex;
  int? _selectedWordIndex;
  bool _isSelecting = false;

  // For shuffling cards animation
  final List<double> _cardOffsets = [];
  final List<double> _cardRotations = [];
  final List<double> _cardScales = [];

  @override
  void initState() {
    super.initState();

    // Set initial remaining time
    _remainingSeconds = widget.selectionTimeSeconds;

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    // Setup confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // Initialize card animation values
    _initializeCardAnimations();

    // Start timer
    _startTimer();
  }

  void _initializeCardAnimations() {
    final random = Random();

    // Initialize with random values
    for (int i = 0; i < widget.wordChoices.length; i++) {
      _cardOffsets.add(random.nextDouble() * 40 - 20); // Between -20 and 20
      _cardRotations.add(
        (random.nextDouble() * 0.2) - 0.1,
      ); // Between -0.1 and 0.1 radians
      _cardScales.add(0.9 + random.nextDouble() * 0.2); // Between 0.9 and 1.1
    }

    // Animate to neutral positions
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          for (int i = 0; i < widget.wordChoices.length; i++) {
            _cardOffsets[i] = 0;
            _cardRotations[i] = 0;
            _cardScales[i] = 1.0;
          }
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();

          // Auto-select a word if time runs out
          if (widget.wordChoices.isNotEmpty) {
            _selectWord(0);
          }
        }
      });
    });
  }

  void _selectWord(int index) {
    if (_isSelecting) return;

    setState(() {
      _isSelecting = true;
      _selectedWordIndex = index;

      // Reset other cards
      for (int i = 0; i < widget.wordChoices.length; i++) {
        if (i != index) {
          _cardOffsets[i] = (i < index ? -200 : 200); // Fly left or right
          _cardRotations[i] = (i < index ? -0.2 : 0.2); // Rotate away
          _cardScales[i] = 0.8; // Shrink
        }
      }

      // Highlight selected card
      _cardScales[index] = 1.1; // Grow
    });

    // Play confetti
    _confettiController.play();

    // Call callback after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _timer?.cancel();
      widget.onWordSelected(widget.wordChoices[index]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti explosion
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              AppTheme.accentColor,
              AppTheme.tertiaryColor,
              Colors.pink,
              Colors.yellow,
            ],
          ),
        ),

        // Background with gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.7),
                AppTheme.tertiaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Card(
                  margin: const EdgeInsets.all(24.0),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with lottie animation
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Lottie.asset(
                                'assets/animations/thinking.json',
                                repeat: true,
                                // If you don't have this animation, replace with:
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.lightbulb,
                                      color: AppTheme.secondaryColor,
                                      size: 32,
                                    ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Header text
                            Text(
                              'Choose a Word',
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'You will draw this word for others to guess!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Timer
                        _buildTimerWidget(),

                        const SizedBox(height: 32),

                        // Word choices
                        ...List.generate(
                          widget.wordChoices.length,
                          (index) => _buildWordChoice(index),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerWidget() {
    // Calculate progress (0.0 to 1.0)
    final progress = _remainingSeconds / widget.selectionTimeSeconds;

    // Determine color based on time remaining
    Color timerColor;
    if (progress > 0.6) {
      timerColor = Colors.green;
    } else if (progress > 0.3) {
      timerColor = AppTheme.warningColor;
    } else {
      timerColor = AppTheme.errorColor;
    }

    return Column(
      children: [
        // Time left text
        Text(
          '$_remainingSeconds seconds left',
          style: TextStyle(
            fontSize: 18,
            color:
                _remainingSeconds <= 5
                    ? AppTheme.errorColor
                    : Colors.grey.shade700,
            fontWeight:
                _remainingSeconds <= 5 ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        const SizedBox(height: 8),

        // Progress bar with animation
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Stack(
              children: [
                // Background track
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                // Progress indicator
                Container(
                  width: MediaQuery.of(context).size.width * 0.7 * value,
                  height: 10,
                  decoration: BoxDecoration(
                    color: timerColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: timerColor.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWordChoice(int index) {
    final word = widget.wordChoices[index];
    final isHovered = _hoveredWordIndex == index;
    final isSelected = _selectedWordIndex == index;

    // Different difficulty colors
    final difficultyColors = [
      Colors.green.shade400, // Easy
      AppTheme.warningColor, // Medium
      AppTheme.errorColor, // Hard
    ];

    final wordColor = difficultyColors[index % difficultyColors.length];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..translate(_cardOffsets[index])
              ..rotateZ(_cardRotations[index])
              ..scale(_cardScales[index]),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [wordColor, wordColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: wordColor.withOpacity(
                  isHovered || isSelected ? 0.5 : 0.3,
                ),
                blurRadius: isHovered || isSelected ? 12 : 4,
                spreadRadius: isHovered || isSelected ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSelecting ? null : () => _selectWord(index),
              onHover: (value) {
                if (!_isSelecting) {
                  setState(() {
                    _hoveredWordIndex = value ? index : null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Difficulty icon
                    Icon(
                      _getDifficultyIcon(index),
                      color: Colors.white,
                      size: 24,
                    ),

                    const SizedBox(width: 12),

                    // Word text
                    Text(
                      word,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Explanation of difficulty
                    if (isHovered && !_isSelecting) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getDifficultyLabel(index),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(int index) {
    switch (index % 3) {
      case 0:
        return Icons.sentiment_very_satisfied; // Easy
      case 1:
        return Icons.sentiment_satisfied; // Medium
      case 2:
        return Icons.sentiment_neutral; // Hard
      default:
        return Icons.sentiment_satisfied;
    }
  }

  String _getDifficultyLabel(int index) {
    switch (index % 3) {
      case 0:
        return 'Easy';
      case 1:
        return 'Medium';
      case 2:
        return 'Challenging';
      default:
        return 'Medium';
    }
  }
}

// Don't forget to add these packages to pubspec.yaml:
// dependencies:
//   lottie: ^2.1.0
//   confetti: ^0.7.0
