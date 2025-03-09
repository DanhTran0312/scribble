import 'package:equatable/equatable.dart';

import 'drawing.dart';
import 'message.dart';
import 'user.dart';

enum RoundStatus { choosing, drawing, ended }

class GameRound extends Equatable {
  final int roundNumber;
  final User drawerUser;
  final String word;
  final List<String> wordChoices;
  final RoundStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final Drawing? drawing;
  final List<Message> messages;
  final Map<String, int> playerScores; // userId to score
  final List<String> playersGuessed; // userIds who guessed correctly

  const GameRound({
    required this.roundNumber,
    required this.drawerUser,
    this.word = '',
    this.wordChoices = const [],
    this.status = RoundStatus.choosing,
    this.startTime,
    this.endTime,
    this.drawing,
    this.messages = const [],
    this.playerScores = const {},
    this.playersGuessed = const [],
  });

  int get remainingTimeInSeconds {
    if (startTime == null || status == RoundStatus.ended) {
      return 0;
    }
    final duration = DateTime.now().difference(startTime!);
    return 80 - duration.inSeconds;
  }

  bool get isActive => status != RoundStatus.ended;
  bool get isDrawing => status == RoundStatus.drawing;
  bool get isChoosing => status == RoundStatus.choosing;
  bool get hasEnded => status == RoundStatus.ended;

  GameRound copyWith({
    int? roundNumber,
    User? drawerUser,
    String? word,
    List<String>? wordChoices,
    RoundStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Drawing? drawing,
    List<Message>? messages,
    Map<String, int>? playerScores,
    List<String>? playersGuessed,
  }) {
    return GameRound(
      roundNumber: roundNumber ?? this.roundNumber,
      drawerUser: drawerUser ?? this.drawerUser,
      word: word ?? this.word,
      wordChoices: wordChoices ?? this.wordChoices,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      drawing: drawing ?? this.drawing,
      messages: messages ?? this.messages,
      playerScores: playerScores ?? this.playerScores,
      playersGuessed: playersGuessed ?? this.playersGuessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'drawerUser': drawerUser.toJson(),
      'word': word,
      'wordChoices': wordChoices,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'drawing': drawing?.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'playerScores': playerScores,
      'playersGuessed': playersGuessed,
    };
  }

  factory GameRound.fromJson(Map<String, dynamic> json) {
    return GameRound(
      roundNumber: json['roundNumber'],
      drawerUser: User.fromJson(json['drawerUser']),
      word: json['word'] ?? '',
      wordChoices: (json['wordChoices'] as List?)
              ?.map((choice) => choice as String)
              .toList() ??
          [],
      status: RoundStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RoundStatus.choosing,
      ),
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      drawing:
          json['drawing'] != null ? Drawing.fromJson(json['drawing']) : null,
      messages: (json['messages'] as List?)
              ?.map((message) => Message.fromJson(message))
              .toList() ??
          [],
      playerScores: (json['playerScores'] as Map?)?.map(
            (key, value) => MapEntry(key as String, value as int),
          ) ??
          {},
      playersGuessed: (json['playersGuessed'] as List?)
              ?.map((id) => id as String)
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        roundNumber,
        drawerUser,
        word,
        wordChoices,
        status,
        startTime,
        endTime,
        drawing,
        messages,
        playerScores,
        playersGuessed,
      ];
}
