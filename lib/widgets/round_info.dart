import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class RoundInfoWidget extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final String drawerName;
  final bool showDetailedInfo;
  final String? currentWord;

  const RoundInfoWidget({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.drawerName,
    this.showDetailedInfo = false,
    this.currentWord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.tertiaryColor.withOpacity(0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child:
            showDetailedInfo
                ? _buildDetailedInfo(context)
                : _buildCompactInfo(context),
      ),
    );
  }

  Widget _buildCompactInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Round indicator
          _buildRoundBadge(),

          const SizedBox(width: 12),

          // Drawer name
          _buildDrawerInfo(),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Left side - Round info
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Round circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$currentRound',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Round text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Round',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currentRound of $totalRounds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            color: Colors.white.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          // Right side - Drawer info
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Drawer icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.brush, color: Colors.white, size: 24),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Drawer name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Artist',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          drawerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
    );
  }

  Widget _buildDrawerInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
    );
  }
}

class RoundProgressIndicator extends StatelessWidget {
  final int currentRound;
  final int totalRounds;

  const RoundProgressIndicator({
    super.key,
    required this.currentRound,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= totalRounds; i++) _buildRoundIndicator(i),
        ],
      ),
    );
  }

  Widget _buildRoundIndicator(int roundNumber) {
    final bool isCompleted = roundNumber < currentRound;
    final bool isCurrent = roundNumber == currentRound;

    Color indicatorColor;
    if (isCompleted) {
      indicatorColor = Colors.green;
    } else if (isCurrent) {
      indicatorColor = AppTheme.primaryColor;
    } else {
      indicatorColor = Colors.grey.shade300;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: isCurrent ? AppTheme.smallShadow : null,
      ),
      child: Center(
        child: Text(
          '$roundNumber',
          style: TextStyle(
            color:
                isCompleted || isCurrent ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
