import 'package:flutter/material.dart';

class RoundInfoWidget extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final String drawerName;

  const RoundInfoWidget({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.drawerName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Round indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'Round $currentRound/$totalRounds',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Drawer name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.brush, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                drawerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(' is drawing', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
