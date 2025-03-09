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
      point: Offset(json['x'].toDouble(), json['y'].toDouble()),
      pressure: json['pressure']?.toDouble() ?? 1.0,
      size: json['size']?.toDouble() ?? 5.0,
    );
  }

  @override
  List<Object?> get props => [point, pressure, size];
}

class DrawStroke extends Equatable {
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;

  const DrawStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 5.0,
    this.strokeCap = StrokeCap.round,
  });

  DrawStroke copyWith({
    List<DrawPoint>? points,
    Color? color,
    double? strokeWidth,
    StrokeCap? strokeCap,
  }) {
    return DrawStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'strokeCap': strokeCap.index,
    };
  }

  factory DrawStroke.fromJson(Map<String, dynamic> json) {
    return DrawStroke(
      points:
          (json['points'] as List)
              .map((point) => DrawPoint.fromJson(point))
              .toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 5.0,
      strokeCap: StrokeCap.values[json['strokeCap'] ?? 0],
    );
  }

  @override
  List<Object?> get props => [points, color, strokeWidth, strokeCap];
}

class Drawing extends Equatable {
  final List<DrawStroke> strokes;
  final Size canvasSize;
  final Color backgroundColor;
  final bool isAiGenerated;
  final String? aiGeneratedWordPrompt;
  final String? imageUrl;

  const Drawing({
    this.strokes = const [],
    this.canvasSize = const Size(800, 600),
    this.backgroundColor = Colors.white,
    this.isAiGenerated = false,
    this.aiGeneratedWordPrompt,
    this.imageUrl,
  });

  Drawing copyWith({
    List<DrawStroke>? strokes,
    Size? canvasSize,
    Color? backgroundColor,
    bool? isAiGenerated,
    String? aiGeneratedWordPrompt,
    String? imageUrl,
  }) {
    return Drawing(
      strokes: strokes ?? this.strokes,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiGeneratedWordPrompt:
          aiGeneratedWordPrompt ?? this.aiGeneratedWordPrompt,
      imageUrl: imageUrl ?? this.imageUrl,
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
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'backgroundColor': backgroundColor.value,
      'isAiGenerated': isAiGenerated,
      'aiGeneratedWordPrompt': aiGeneratedWordPrompt,
      'imageUrl': imageUrl,
    };
  }

  factory Drawing.fromJson(Map<String, dynamic> json) {
    return Drawing(
      strokes:
          (json['strokes'] as List?)
              ?.map((stroke) => DrawStroke.fromJson(stroke))
              .toList() ??
          [],
      canvasSize: Size(
        json['canvasWidth']?.toDouble() ?? 800,
        json['canvasHeight']?.toDouble() ?? 600,
      ),
      backgroundColor: Color(json['backgroundColor'] ?? Colors.white.value),
      isAiGenerated: json['isAiGenerated'] ?? false,
      aiGeneratedWordPrompt: json['aiGeneratedWordPrompt'],
      imageUrl: json['imageUrl'],
    );
  }

  @override
  List<Object?> get props => [
    strokes,
    canvasSize,
    backgroundColor,
    isAiGenerated,
    aiGeneratedWordPrompt,
    imageUrl,
  ];
}
