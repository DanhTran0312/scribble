import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 40,
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
      timerColor = Colors.red;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Circular progress
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: timerColor,
            strokeWidth: 4,
          ),
        ),

        // Time text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              remainingSeconds.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35,
                color: timerColor,
              ),
            ),
            Text(
              'sec',
              style: TextStyle(
                fontSize: size * 0.2,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
