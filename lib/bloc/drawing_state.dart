import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/drawing.dart';

abstract class DrawingState extends Equatable {
  const DrawingState();

  @override
  List<Object?> get props => [];
}

class DrawingInitial extends DrawingState {}

class DrawingReady extends DrawingState {
  final Drawing drawing;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isDrawing;
  final bool isAiGenerating;
  final String? error;

  const DrawingReady({
    required this.drawing,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isDrawing = false,
    this.isAiGenerating = false,
    this.error,
  });

  DrawingReady copyWith({
    Drawing? drawing,
    Color? currentColor,
    double? currentStrokeWidth,
    bool? isDrawing,
    bool? isAiGenerating,
    String? error,
  }) {
    return DrawingReady(
      drawing: drawing ?? this.drawing,
      currentColor: currentColor ?? this.currentColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
      isDrawing: isDrawing ?? this.isDrawing,
      isAiGenerating: isAiGenerating ?? this.isAiGenerating,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    drawing,
    currentColor,
    currentStrokeWidth,
    isDrawing,
    isAiGenerating,
    error,
  ];
}
