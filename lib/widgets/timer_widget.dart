import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class TimerWidget extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;
  final bool showWarning;
  final VoidCallback? onTimeExpired;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 80,
    this.showWarning = true,
    this.onTimeExpired,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isAlmostFinished = false;
  int _previousSeconds = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed && _isAlmostFinished) {
        _animationController.forward();
      }
    });

    _checkTimeStatus();
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we should play the animation
    if (widget.remainingSeconds != _previousSeconds) {
      _checkTimeStatus();
      _previousSeconds = widget.remainingSeconds;

      // Check if time expired
      if (widget.remainingSeconds == 0 && oldWidget.remainingSeconds > 0) {
        widget.onTimeExpired?.call();
      }
    }
  }

  void _checkTimeStatus() {
    final isNowAlmostFinished =
        widget.showWarning &&
        widget.remainingSeconds <= 10 &&
        widget.remainingSeconds > 0;

    if (isNowAlmostFinished && !_isAlmostFinished) {
      // Just entered warning state
      _animationController.forward();
    } else if (!isNowAlmostFinished && _isAlmostFinished) {
      // Just exited warning state
      _animationController.stop();
      _animationController.reset();
    }

    _isAlmostFinished = isNowAlmostFinished;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.0 to 1.0)
    final progress = widget.remainingSeconds / widget.totalSeconds;

    // Determine color based on time remaining
    Color timerColor;
    if (progress > 0.6) {
      timerColor = Colors.green;
    } else if (progress > 0.3) {
      timerColor = AppTheme.warningColor;
    } else {
      timerColor = AppTheme.errorColor;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAlmostFinished ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: widget.size * 1.2,
        padding: EdgeInsets.all(_isAlmostFinished ? 8 : 4),
        decoration: BoxDecoration(
          color:
              _isAlmostFinished
                  ? AppTheme.errorColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator with animated fill
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: progress + 0.01, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow:
                              _isAlmostFinished
                                  ? [
                                    BoxShadow(
                                      color: AppTheme.errorColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                  : null,
                        ),
                      ),

                      // Progress indicator
                      ShaderMask(
                        shaderCallback: (rect) {
                          return SweepGradient(
                            startAngle: -0.5 * 3.14,
                            endAngle: 1.5 * 3.14,
                            colors: [
                              timerColor,
                              timerColor,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            stops: [
                              0.0,
                              animatedProgress,
                              animatedProgress,
                              1.0,
                            ],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Inner white circle for content
                      Center(
                        child: Container(
                          width: widget.size * 0.85,
                          height: widget.size * 0.85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Time display with animated counting effect
            TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: widget.remainingSeconds + 1,
                end: widget.remainingSeconds,
              ),
              duration: const Duration(milliseconds: 300),
              builder: (context, animatedSeconds, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seconds remaining with clock icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.timer,
                          size: widget.size * 0.2,
                          color: timerColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$animatedSeconds',
                          style: GoogleFonts.fredoka(
                            fontSize: widget.size * 0.35,
                            color: timerColor,
                          ),
                        ),
                      ],
                    ),

                    // "sec" label
                    Text(
                      'sec',
                      style: TextStyle(
                        fontSize: widget.size * 0.18,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),

            // Warning indicators for low time
            if (_isAlmostFinished) _buildWarningIndicator(timerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final opacity = sin(_animationController.value * 3.14) * 0.7;
        return Positioned.fill(
          child: Opacity(
            opacity: opacity > 0 ? opacity : 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.errorColor, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}
