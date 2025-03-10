import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DrawPoint extends Equatable {
  final Offset point;
  final double pressure;
  final double size;

  const DrawPoint({required this.point, this.pressure = 1.0, this.size = 5.0});

  Map<String, dynamic> toJson() {
    return {'x': point.dx, 'y': point.dy, 'pressure': pressure, 'size': size};
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      point: Offset((json['x'] ?? 0).toDouble(), (json['y'] ?? 0).toDouble()),
      pressure: (json['pressure'] ?? 1.0).toDouble(),
      size: (json['size'] ?? 5.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [point, pressure, size];
}

class DrawStroke extends Equatable {
  final String id; // Added id field
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;

  const DrawStroke({
    this.id = '',
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 5.0,
    this.strokeCap = StrokeCap.round,
  });

  DrawStroke copyWith({
    String? id,
    List<DrawPoint>? points,
    Color? color,
    double? strokeWidth,
    StrokeCap? strokeCap,
  }) {
    return DrawStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((point) => point.toJson()).toList(),
      'color': color.value,
      'stroke_width': strokeWidth, // Snake case for backend
      'stroke_cap': strokeCap.index, // Snake case for backend
    };
  }

  factory DrawStroke.fromJson(Map<String, dynamic> json) {
    return DrawStroke(
      id: json['id'] ?? '',
      points:
          json['points'] != null
              ? (json['points'] as List)
                  .map((point) => DrawPoint.fromJson(point))
                  .toList()
              : [],
      color: Color(json['color'] ?? Colors.black.value),
      strokeWidth:
          (json['stroke_width'] ?? json['strokeWidth'] ?? 5.0).toDouble(),
      strokeCap:
          StrokeCap.values[json['stroke_cap'] ??
              json['strokeCap'] ??
              StrokeCap.round.index],
    );
  }

  @override
  List<Object?> get props => [id, points, color, strokeWidth, strokeCap];
}

class Drawing extends Equatable {
  final String id; // Added id field
  final List<DrawStroke> strokes;
  final Size canvasSize;
  final Color backgroundColor;
  final bool isAiGenerated;
  final String? aiGeneratedWordPrompt;
  final String? imageUrl;
  final DateTime? createdAt; // Added timestamp

  const Drawing({
    this.id = '',
    this.strokes = const [],
    this.canvasSize = const Size(800, 600),
    this.backgroundColor = Colors.white,
    this.isAiGenerated = false,
    this.aiGeneratedWordPrompt,
    this.imageUrl,
    this.createdAt,
  });

  Drawing copyWith({
    String? id,
    List<DrawStroke>? strokes,
    Size? canvasSize,
    Color? backgroundColor,
    bool? isAiGenerated,
    String? aiGeneratedWordPrompt,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Drawing(
      id: id ?? this.id,
      strokes: strokes ?? this.strokes,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiGeneratedWordPrompt:
          aiGeneratedWordPrompt ?? this.aiGeneratedWordPrompt,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Drawing addStroke(DrawStroke stroke) {
    return copyWith(strokes: [...strokes, stroke]);
  }

  Drawing updateLastStroke(DrawPoint point) {
    if (strokes.isEmpty) {
      return this;
    }

    final lastStroke = strokes.last;
    final updatedPoints = [...lastStroke.points, point];
    final updatedStroke = lastStroke.copyWith(points: updatedPoints);

    return copyWith(
      strokes: [...strokes.sublist(0, strokes.length - 1), updatedStroke],
    );
  }

  Drawing clear() {
    return copyWith(strokes: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'canvas_width': canvasSize.width, // Snake case for backend
      'canvas_height': canvasSize.height, // Snake case for backend
      'background_color': backgroundColor.value, // Snake case for backend
      'is_ai_generated': isAiGenerated, // Snake case for backend
      'ai_generated_word_prompt':
          aiGeneratedWordPrompt, // Snake case for backend
      'image_url': imageUrl, // Snake case for backend
      'created_at': createdAt?.toIso8601String(), // Snake case for backend
    };
  }

  factory Drawing.fromJson(Map<String, dynamic> json) {
    return Drawing(
      id: json['id'] ?? '',
      strokes:
          json['strokes'] != null
              ? (json['strokes'] as List)
                  .map((stroke) => DrawStroke.fromJson(stroke))
                  .toList()
              : [],
      canvasSize: Size(
        (json['canvas_width'] ?? json['canvasWidth'] ?? 800).toDouble(),
        (json['canvas_height'] ?? json['canvasHeight'] ?? 600).toDouble(),
      ),
      backgroundColor: Color(
        json['background_color'] ??
            json['backgroundColor'] ??
            Colors.white.value,
      ),
      isAiGenerated: json['is_ai_generated'] ?? json['isAiGenerated'] ?? false,
      aiGeneratedWordPrompt:
          json['ai_generated_word_prompt'] ?? json['aiGeneratedWordPrompt'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      createdAt:
          json['created_at'] != null || json['createdAt'] != null
              ? DateTime.parse(json['created_at'] ?? json['createdAt'])
              : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    strokes,
    canvasSize,
    backgroundColor,
    isAiGenerated,
    aiGeneratedWordPrompt,
    imageUrl,
    createdAt,
  ];
}

// Drawing Update to be sent to the server
class DrawingUpdate extends Equatable {
  final DrawStroke? addStroke;
  final DrawPoint? addPointToLastStroke;
  final bool undoLastStroke;
  final bool clear;

  const DrawingUpdate({
    this.addStroke,
    this.addPointToLastStroke,
    this.undoLastStroke = false,
    this.clear = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (addStroke != null) 'add_stroke': addStroke!.toJson(),
      if (addPointToLastStroke != null)
        'add_point_to_last_stroke': addPointToLastStroke!.toJson(),
      if (undoLastStroke) 'undo_last_stroke': true,
      if (clear) 'clear': true,
    };
  }

  @override
  List<Object?> get props => [
    addStroke,
    addPointToLastStroke,
    undoLastStroke,
    clear,
  ];
}

// AI Drawing Request
class AIDrawingRequest extends Equatable {
  final String wordPrompt;
  final String style;

  const AIDrawingRequest({required this.wordPrompt, this.style = 'doodle'});

  Map<String, dynamic> toJson() {
    return {'word_prompt': wordPrompt, 'style': style};
  }

  @override
  List<Object?> get props => [wordPrompt, style];
}

// AI Drawing Response
class AIDrawingResponse extends Equatable {
  final String id;
  final String imageUrl;
  final String wordPrompt;
  final List<DrawStroke>? tracedStrokes;

  const AIDrawingResponse({
    required this.id,
    required this.imageUrl,
    required this.wordPrompt,
    this.tracedStrokes,
  });

  factory AIDrawingResponse.fromJson(Map<String, dynamic> json) {
    return AIDrawingResponse(
      id: json['id'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      wordPrompt: json['word_prompt'] ?? json['wordPrompt'] ?? '',
      tracedStrokes:
          json['traced_strokes'] != null
              ? (json['traced_strokes'] as List)
                  .map((stroke) => DrawStroke.fromJson(stroke))
                  .toList()
              : null,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, wordPrompt, tracedStrokes];
}
