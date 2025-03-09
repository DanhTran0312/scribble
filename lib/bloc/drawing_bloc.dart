import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/drawing.dart';
import '../../services/ai_drawing_service.dart';
import '../../services/line_tracing_service.dart';
import 'drawing_event.dart';
import 'drawing_state.dart';

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  final AiDrawingService aiDrawingService;
  final LineTracingService lineTracingService;

  DrawingBloc({
    required this.aiDrawingService,
    required this.lineTracingService,
  }) : super(DrawingInitial()) {
    on<DrawingStarted>(_onDrawingStarted);
    on<DrawingEnded>(_onDrawingEnded);
    on<DrawingCanvasCleared>(_onDrawingCanvasCleared);
    on<DrawingColorChanged>(_onDrawingColorChanged);
    on<DrawingStrokeWidthChanged>(_onDrawingStrokeWidthChanged);
    on<DrawingPointerDown>(_onDrawingPointerDown);
    on<DrawingPointerMove>(_onDrawingPointerMove);
    on<DrawingPointerUp>(_onDrawingPointerUp);
    on<DrawingUndoLastStroke>(_onDrawingUndoLastStroke);
    on<DrawingAiGenerated>(_onDrawingAiGenerated);
    on<DrawingReceived>(_onDrawingReceived);
  }

  void _onDrawingStarted(DrawingStarted event, Emitter<DrawingState> emit) {
    final drawing = Drawing(
      canvasSize: event.canvasSize,
      backgroundColor: Colors.white,
    );

    emit(
      DrawingReady(
        drawing: drawing,
        currentColor: Colors.black,
        currentStrokeWidth: 5.0,
        isAiGenerating: false,
      ),
    );
  }

  void _onDrawingEnded(DrawingEnded event, Emitter<DrawingState> emit) {
    emit(DrawingInitial());
  }

  void _onDrawingCanvasCleared(
    DrawingCanvasCleared event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady) {
      emit(currentState.copyWith(drawing: currentState.drawing.clear()));
    }
  }

  void _onDrawingColorChanged(
    DrawingColorChanged event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady) {
      emit(currentState.copyWith(currentColor: event.color));
    }
  }

  void _onDrawingStrokeWidthChanged(
    DrawingStrokeWidthChanged event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady) {
      emit(currentState.copyWith(currentStrokeWidth: event.strokeWidth));
    }
  }

  void _onDrawingPointerDown(
    DrawingPointerDown event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady) {
      final point = DrawPoint(
        point: event.position,
        pressure: event.pressure,
        size: currentState.currentStrokeWidth,
      );

      final stroke = DrawStroke(
        points: [point],
        color: currentState.currentColor,
        strokeWidth: currentState.currentStrokeWidth,
      );

      final updatedDrawing = currentState.drawing.addStroke(stroke);

      emit(currentState.copyWith(drawing: updatedDrawing, isDrawing: true));
    }
  }

  void _onDrawingPointerMove(
    DrawingPointerMove event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady && currentState.isDrawing) {
      final point = DrawPoint(
        point: event.position,
        pressure: event.pressure,
        size: currentState.currentStrokeWidth,
      );

      final updatedDrawing = currentState.drawing.updateLastStroke(point);

      emit(currentState.copyWith(drawing: updatedDrawing));
    }
  }

  void _onDrawingPointerUp(DrawingPointerUp event, Emitter<DrawingState> emit) {
    final currentState = state;
    if (currentState is DrawingReady && currentState.isDrawing) {
      emit(currentState.copyWith(isDrawing: false));
    }
  }

  void _onDrawingUndoLastStroke(
    DrawingUndoLastStroke event,
    Emitter<DrawingState> emit,
  ) {
    final currentState = state;
    if (currentState is DrawingReady &&
        currentState.drawing.strokes.isNotEmpty) {
      final updatedStrokes = List<DrawStroke>.from(currentState.drawing.strokes)
        ..removeLast();

      final updatedDrawing = currentState.drawing.copyWith(
        strokes: updatedStrokes,
      );

      emit(currentState.copyWith(drawing: updatedDrawing));
    }
  }

  Future<void> _onDrawingAiGenerated(
    DrawingAiGenerated event,
    Emitter<DrawingState> emit,
  ) async {
    final currentState = state;
    if (currentState is DrawingReady) {
      emit(currentState.copyWith(isAiGenerating: true));

      try {
        // Generate an AI drawing
        final aiDrawingResult = await aiDrawingService.generateDrawing(
          prompt: event.wordPrompt,
        );

        // Trace the lines from the AI drawing
        final tracedStrokes = await lineTracingService.traceImage(
          aiDrawingResult.imageUrl,
        );

        final aiDrawing = Drawing(
          strokes: tracedStrokes,
          canvasSize: currentState.drawing.canvasSize,
          backgroundColor: Colors.white,
          isAiGenerated: true,
          aiGeneratedWordPrompt: event.wordPrompt,
          imageUrl: aiDrawingResult.imageUrl,
        );

        emit(currentState.copyWith(drawing: aiDrawing, isAiGenerating: false));
      } catch (error) {
        emit(
          currentState.copyWith(isAiGenerating: false, error: error.toString()),
        );
      }
    }
  }

  void _onDrawingReceived(DrawingReceived event, Emitter<DrawingState> emit) {
    final currentState = state;
    if (currentState is DrawingReady) {
      emit(currentState.copyWith(drawing: event.drawing));
    } else {
      emit(
        DrawingReady(
          drawing: event.drawing,
          currentColor: Colors.black,
          currentStrokeWidth: 5.0,
          isAiGenerating: false,
        ),
      );
    }
  }
}
