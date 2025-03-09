import 'dart:async';

import 'package:flutter/material.dart';

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
  late Animation<double> _animation;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Set initial remaining time
    _remainingSeconds = widget.selectionTimeSeconds;

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _controller.forward();

    // Start timer
    _startTimer();
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
            widget.onWordSelected(widget.wordChoices.first);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
            Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Card(
              margin: const EdgeInsets.all(24.0),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    const Text(
                      'Choose a Word',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'You will draw this word for others to guess',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Timer
                    Text(
                      '$_remainingSeconds seconds left',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _remainingSeconds <= 5
                                ? Colors.red
                                : Colors.grey.shade700,
                        fontWeight:
                            _remainingSeconds <= 5
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),

                    const SizedBox(height: 8),

                    LinearProgressIndicator(
                      value: _remainingSeconds / widget.selectionTimeSeconds,
                      backgroundColor: Colors.grey.shade200,
                      color:
                          _remainingSeconds <= 5
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(height: 32),

                    // Word choices
                    ...widget.wordChoices.map((word) => _buildWordChoice(word)),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordChoice(String word) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: () {
          _timer?.cancel();
          widget.onWordSelected(word);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: Text(word),
      ),
    );
  }
}
