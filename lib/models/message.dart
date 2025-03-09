import 'package:equatable/equatable.dart';

import 'user.dart';

enum MessageType { chat, system, guessCorrect, drawing }

class Message extends Equatable {
  final String id;
  final User? sender;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isCorrectGuess;

  const Message({
    required this.id,
    this.sender,
    required this.content,
    required this.timestamp,
    this.type = MessageType.chat,
    this.isCorrectGuess = false,
  });

  Message copyWith({
    String? id,
    User? sender,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isCorrectGuess,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isCorrectGuess: isCorrectGuess ?? this.isCorrectGuess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender?.toJson(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isCorrectGuess': isCorrectGuess,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.chat,
      ),
      isCorrectGuess: json['isCorrectGuess'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        content,
        timestamp,
        type,
        isCorrectGuess,
      ];
}
