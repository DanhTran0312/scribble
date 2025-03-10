import 'package:equatable/equatable.dart';

import 'user.dart';

enum MessageType { chat, system, guessCorrect, drawing, hint }

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
      'is_correct_guess': isCorrectGuess, // Snake case for backend
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'] ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      type: _parseMessageType(json['type']),
      isCorrectGuess:
          json['is_correct_guess'] ?? json['isCorrectGuess'] ?? false,
    );
  }

  static MessageType _parseMessageType(String? type) {
    if (type == null) return MessageType.chat;

    switch (type.toLowerCase()) {
      case 'chat':
        return MessageType.chat;
      case 'system':
        return MessageType.system;
      case 'guesscorrect':
      case 'guess_correct':
        return MessageType.guessCorrect;
      case 'drawing':
        return MessageType.drawing;
      case 'hint':
        return MessageType.hint;
      default:
        return MessageType.chat;
    }
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

// Chat message to be sent to the server
class ChatMessage {
  final String content;
  final String roomId;

  ChatMessage({required this.content, required this.roomId});

  Map<String, dynamic> toJson() {
    return {'content': content, 'room_id': roomId};
  }
}
