import 'package:equatable/equatable.dart';

import 'drawing.dart';
import 'message.dart';
import 'user.dart';

enum RoundStatus { choosing, drawing, ended }

class GameRound extends Equatable {
  final String id; // Added id field
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
  final int timeLimit; // Added explicit time limit

  const GameRound({
    this.id = '',
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
    this.timeLimit = 80,
  });

  int get remainingTimeInSeconds {
    if (startTime == null || status == RoundStatus.ended) {
      return 0;
    }
    final duration = DateTime.now().difference(startTime!);
    return timeLimit - duration.inSeconds.clamp(0, timeLimit);
  }

  bool get isActive => status != RoundStatus.ended;
  bool get isDrawing => status == RoundStatus.drawing;
  bool get isChoosing => status == RoundStatus.choosing;
  bool get hasEnded => status == RoundStatus.ended;

  GameRound copyWith({
    String? id,
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
    int? timeLimit,
  }) {
    return GameRound(
      id: id ?? this.id,
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
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'round_number': roundNumber, // Snake case for backend
      'drawer_user': drawerUser.toJson(), // Snake case for backend
      'word': word,
      'word_choices': wordChoices, // Snake case for backend
      'status': status.name,
      'start_time': startTime?.toIso8601String(), // Snake case for backend
      'end_time': endTime?.toIso8601String(), // Snake case for backend
      'drawing': drawing?.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'player_scores': playerScores, // Snake case for backend
      'players_guessed': playersGuessed, // Snake case for backend
      'time_limit': timeLimit, // Snake case for backend
    };
  }

  factory GameRound.fromJson(Map<String, dynamic> json) {
    return GameRound(
      id: json['id'] ?? '',
      roundNumber: json['round_number'] ?? json['roundNumber'] ?? 0,
      drawerUser:
          json['drawer_user'] != null || json['drawerUser'] != null
              ? User.fromJson(json['drawer_user'] ?? json['drawerUser'])
              : User(id: '', username: 'Unknown'),
      word: json['word'] ?? '',
      wordChoices: _parseStringList(
        json['word_choices'] ?? json['wordChoices'],
      ),
      status: _parseRoundStatus(json['status']),
      startTime:
          json['start_time'] != null || json['startTime'] != null
              ? DateTime.parse(json['start_time'] ?? json['startTime'])
              : null,
      endTime:
          json['end_time'] != null || json['endTime'] != null
              ? DateTime.parse(json['end_time'] ?? json['endTime'])
              : null,
      drawing:
          json['drawing'] != null ? Drawing.fromJson(json['drawing']) : null,
      messages:
          json['messages'] != null
              ? (json['messages'] as List)
                  .map((msg) => Message.fromJson(msg))
                  .toList()
              : [],
      playerScores: _parsePlayerScores(
        json['player_scores'] ?? json['playerScores'],
      ),
      playersGuessed: _parseStringList(
        json['players_guessed'] ?? json['playersGuessed'],
      ),
      timeLimit: json['time_limit'] ?? json['timeLimit'] ?? 80,
    );
  }

  static List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    }
    return [];
  }

  static Map<String, int> _parsePlayerScores(dynamic scores) {
    if (scores == null) return {};
    if (scores is Map) {
      return scores.map(
        (key, value) =>
            MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0),
      );
    }
    return {};
  }

  static RoundStatus _parseRoundStatus(String? status) {
    if (status == null) return RoundStatus.choosing;

    switch (status.toLowerCase()) {
      case 'choosing':
        return RoundStatus.choosing;
      case 'drawing':
        return RoundStatus.drawing;
      case 'ended':
        return RoundStatus.ended;
      default:
        return RoundStatus.choosing;
    }
  }

  @override
  List<Object?> get props => [
    id,
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
    timeLimit,
  ];
}
