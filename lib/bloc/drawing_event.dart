import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/drawing.dart';

abstract class DrawingEvent extends Equatable {
  const DrawingEvent();

  @override
  List<Object?> get props => [];
}

class DrawingStarted extends DrawingEvent {
  final Size canvasSize;

  const DrawingStarted({this.canvasSize = const Size(800, 600)});

  @override
  List<Object> get props => [canvasSize];
}

class DrawingEnded extends DrawingEvent {}

class DrawingCanvasCleared extends DrawingEvent {}

class DrawingColorChanged extends DrawingEvent {
  final Color color;

  const DrawingColorChanged(this.color);

  @override
  List<Object> get props => [color];
}

class DrawingStrokeWidthChanged extends DrawingEvent {
  final double strokeWidth;

  const DrawingStrokeWidthChanged(this.strokeWidth);

  @override
  List<Object> get props => [strokeWidth];
}

class DrawingPointerDown extends DrawingEvent {
  final Offset position;
  final double pressure;

  const DrawingPointerDown({required this.position, this.pressure = 1.0});

  @override
  List<Object> get props => [position, pressure];
}

class DrawingPointerMove extends DrawingEvent {
  final Offset position;
  final double pressure;

  const DrawingPointerMove({required this.position, this.pressure = 1.0});

  @override
  List<Object> get props => [position, pressure];
}

class DrawingPointerUp extends DrawingEvent {
  final Offset position;

  const DrawingPointerUp({required this.position});

  @override
  List<Object> get props => [position];
}

class DrawingUndoLastStroke extends DrawingEvent {}

class DrawingAiGenerated extends DrawingEvent {
  final String wordPrompt;

  const DrawingAiGenerated(this.wordPrompt);

  @override
  List<Object> get props => [wordPrompt];
}

class DrawingReceived extends DrawingEvent {
  final Drawing drawing;

  const DrawingReceived(this.drawing);

  @override
  List<Object> get props => [drawing];
}
