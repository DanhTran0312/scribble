import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/api_constants.dart';
import 'api_client.dart';

enum MessageType {
  chat,
  drawing,
  gameAction,
  gameStateUpdate,
  userConnected,
  userDisconnected,
  error,
}

class WebSocketMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  WebSocketMessage({required this.type, required this.data});

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: _parseMessageType(json['type']),
      data: json['data'] ?? {},
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'chat':
        return MessageType.chat;
      case 'drawing':
        return MessageType.drawing;
      case 'game_action':
        return MessageType.gameAction;
      case 'game_state_update':
        return MessageType.gameStateUpdate;
      case 'user_connected':
        return MessageType.userConnected;
      case 'user_disconnected':
        return MessageType.userDisconnected;
      case 'error':
        return MessageType.error;
      default:
        return MessageType.error;
    }
  }

  Map<String, dynamic> toJson() {
    return {'type': type.toString().split('.').last, 'data': data};
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  final String roomId;
  final ApiClient _apiClient = ApiClient();

  bool _isConnected = false;

  // Message controllers
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  // Typed stream controllers for different message types
  final StreamController<Map<String, dynamic>> _chatController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _drawingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Connection status stream
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  WebSocketService({required this.roomId});

  // Connect to WebSocket
  void connect() {
    if (_isConnected) return;

    // Ensure API client is initialized
    if (_apiClient.authToken == null) {
      _errorController.add({
        'message': 'Not authenticated. Please log in first.',
      });
      return;
    }

    try {
      final wsUrl = ApiConstants.roomWebSocket(roomId);

      // Add auth token to URL
      final uri = Uri.parse('$wsUrl?token=${_apiClient.authToken}');

      _channel = WebSocketChannel.connect(uri);

      // Listen for messages
      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);

      _isConnected = true;
      _connectionStatusController.add(true);
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      _errorController.add({'message': 'Failed to connect to WebSocket: $e'});
    }
  }

  // Disconnect WebSocket
  void disconnect() {
    if (!_isConnected) return;

    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  // Send a message
  void sendMessage(MessageType type, Map<String, dynamic> data) {
    if (!_isConnected) {
      _errorController.add({'message': 'Not connected to WebSocket.'});
      return;
    }

    final message = WebSocketMessage(type: type, data: data);
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  // Send a chat message
  void sendChatMessage(String content) {
    sendMessage(MessageType.chat, {'content': content, 'room_id': roomId});
  }

  // Send a drawing update
  void sendDrawingUpdate(Map<String, dynamic> drawingData) {
    sendMessage(MessageType.drawing, drawingData);
  }

  // Send a game action
  void sendGameAction(String action, Map<String, dynamic> actionData) {
    sendMessage(MessageType.gameAction, {'action': action, 'data': actionData});
  }

  // Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final jsonData = jsonDecode(message as String);
      final wsMessage = WebSocketMessage.fromJson(jsonData);

      // Add to main message stream
      _messageController.add(wsMessage);

      // Add to type-specific streams
      switch (wsMessage.type) {
        case MessageType.chat:
          _chatController.add(wsMessage.data);
          break;
        case MessageType.drawing:
          _drawingController.add(wsMessage.data);
          break;
        case MessageType.gameStateUpdate:
          _gameStateController.add(wsMessage.data);
          break;
        case MessageType.userConnected:
        case MessageType.userDisconnected:
          _userController.add(wsMessage.data);
          break;
        case MessageType.error:
          _errorController.add(wsMessage.data);
          break;
        default:
          // Unhandled message type
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  // Handle WebSocket errors
  void _onError(error) {
    _errorController.add({'message': 'WebSocket error: $error'});

    _isConnected = false;
    _connectionStatusController.add(false);
  }

  // Handle WebSocket close
  void _onDone() {
    _isConnected = false;
    _connectionStatusController.add(false);

    // Try to reconnect after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  // Stream getters
  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get chatMessages => _chatController.stream;
  Stream<Map<String, dynamic>> get drawingUpdates => _drawingController.stream;
  Stream<Map<String, dynamic>> get gameStateUpdates =>
      _gameStateController.stream;
  Stream<Map<String, dynamic>> get userUpdates => _userController.stream;
  Stream<Map<String, dynamic>> get errors => _errorController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Connection status getter
  bool get isConnected => _isConnected;

  // Cleanup
  void dispose() {
    disconnect();

    _messageController.close();
    _chatController.close();
    _drawingController.close();
    _gameStateController.close();
    _userController.close();
    _errorController.close();
    _connectionStatusController.close();
  }
}
