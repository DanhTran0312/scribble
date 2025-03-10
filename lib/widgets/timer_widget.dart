import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;
  final bool showWarning;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 60,
    this.showWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.0 to 1.0)
    final progress = remainingSeconds / totalSeconds;

    // Determine color based on time remaining
    Color timerColor;
    if (progress > 0.6) {
      timerColor = Colors.green;
    } else if (progress > 0.3) {
      timerColor = Colors.orange;
    } else {
      timerColor = AppTheme.errorColor;
    }

    // Configure animation for low time
    final shouldAnimate =
        showWarning && remainingSeconds <= 10 && remainingSeconds > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(shouldAnimate ? 8 : 4),
      decoration: BoxDecoration(
        color:
            shouldAnimate
                ? AppTheme.errorColor.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: shouldAnimate ? AppTheme.smallShadow : null,
            ),
          ),

          // Progress indicator
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              color: timerColor,
              strokeWidth: size / 10,
            ),
          ),

          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time remaining
              Text(
                remainingSeconds.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.35,
                  color: shouldAnimate ? AppTheme.errorColor : timerColor,
                ),
              ),

              // "sec" label
              Text(
                'sec',
                style: TextStyle(
                  fontSize: size * 0.2,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Pulse overlay for animation
          if (shouldAnimate)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity:
                      (value - 0.8) * 5, // Makes opacity pulse between 0 and 1
                  child: Transform.scale(
                    scale: value,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
              // When animation completes, it automatically restarts
              onEnd: () => (context as Element).markNeedsBuild(),
            ),
        ],
      ),
    );
  }
}
