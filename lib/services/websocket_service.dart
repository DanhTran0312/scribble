import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    if (type == null) return MessageType.error;

    switch (type.toLowerCase()) {
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
      default:
        return MessageType.error;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last.toLowerCase(),
      'data': data,
    };
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  String roomId;
  final ApiClient _apiClient = ApiClient();
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const int HEARTBEAT_INTERVAL_SECONDS = 30;

  // Stream controllers for different message types
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();
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
    if (_isConnected || _isReconnecting) return;

    _reconnectAttempts = 0;
    _connectInternal();
  }

  void _connectInternal() {
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

      if (kDebugMode) {
        print('Connecting to WebSocket: $uri');
      }

      _channel = WebSocketChannel.connect(uri);

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _isReconnecting = false;
      _connectionStatusController.add(true);

      // Start heartbeat timer
      _startHeartbeat();

      if (kDebugMode) {
        print('WebSocket connected');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      _errorController.add({'message': 'Failed to connect to WebSocket: $e'});

      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }

      _attemptReconnect();
    }
  }

  // Start heartbeat timer to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: HEARTBEAT_INTERVAL_SECONDS),
      (_) => _sendHeartbeat(),
    );
  }

  // Send heartbeat message
  void _sendHeartbeat() {
    if (_isConnected) {
      try {
        _channel?.sink.add(
          jsonEncode({
            'type': 'heartbeat',
            'data': {'timestamp': DateTime.now().toIso8601String()},
          }),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error sending heartbeat: $e');
        }
      }
    }
  }

  // Disconnect WebSocket
  void disconnect({bool isForced = false}) {
    if (!_isConnected && !isForced) return;

    _cancelReconnect();
    _heartbeatTimer?.cancel();
    _isConnected = false;
    _isReconnecting = false;
    _connectionStatusController.add(false);

    try {
      _channel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        print('Error closing WebSocket: $e');
      }
    }

    if (kDebugMode) {
      print('WebSocket disconnected');
    }
  }

  // Send a message
  void sendMessage(MessageType type, Map<String, dynamic> data) {
    if (!_isConnected) {
      _errorController.add({'message': 'Not connected to WebSocket.'});
      return;
    }

    final message = WebSocketMessage(type: type, data: data);
    final jsonString = jsonEncode(message.toJson());

    try {
      _channel?.sink.add(jsonString);

      if (kDebugMode) {
        print('Sent WebSocket message: ${message.type}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending WebSocket message: $e');
      }
      _errorController.add({'message': 'Failed to send message: $e'});

      // Try to reconnect if sending fails
      _onError(e);
    }
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
      if (kDebugMode) {
        print('Received WebSocket message: $message');
      }

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
      _errorController.add({'message': 'Failed to parse message: $e'});
    }
  }

  // Handle WebSocket errors
  void _onError(dynamic error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }

    _errorController.add({'message': 'WebSocket error: $error'});
    _isConnected = false;
    _connectionStatusController.add(false);

    _attemptReconnect();
  }

  // Handle WebSocket close
  void _onDone() {
    if (kDebugMode) {
      print('WebSocket connection closed');
    }

    _isConnected = false;
    _connectionStatusController.add(false);

    _attemptReconnect();
  }

  // Attempt to reconnect
  void _attemptReconnect() {
    // Don't attempt to reconnect if already reconnecting
    if (_isReconnecting) return;

    _isReconnecting = true;
    _reconnectAttempts++;

    if (_reconnectAttempts <= MAX_RECONNECT_ATTEMPTS) {
      if (kDebugMode) {
        print(
          'Attempting to reconnect ($_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS)...',
        );
      }

      // Exponential backoff: 1s, 2s, 4s, 8s, 16s
      final delay = Duration(seconds: 1 << (_reconnectAttempts - 1));

      _reconnectTimer = Timer(delay, () {
        _connectInternal();
      });
    } else {
      if (kDebugMode) {
        print('Max reconnect attempts reached. Giving up.');
      }

      _errorController.add({
        'message':
            'Failed to reconnect after $MAX_RECONNECT_ATTEMPTS attempts.',
      });

      _isReconnecting = false;
    }
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
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
    disconnect(isForced: true);
    _cancelReconnect();
    _heartbeatTimer?.cancel();

    _messageController.close();
    _chatController.close();
    _drawingController.close();
    _gameStateController.close();
    _userController.close();
    _errorController.close();
    _connectionStatusController.close();
  }
}
