import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game_round.dart';
import '../models/message.dart';
import '../models/room.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';
import 'websocket_service.dart';

class RoomService {
  final ApiClient _apiClient = ApiClient();
  WebSocketService? _wsService;

  final StreamController<Room> _roomUpdatesController =
      StreamController<Room>.broadcast();
  final StreamController<GameRound> _roundUpdatesController =
      StreamController<GameRound>.broadcast();
  final StreamController<List<Message>> _messageUpdatesController =
      StreamController<List<Message>>.broadcast();

  // Get available rooms
  Future<List<Room>> getAvailableRooms() async {
    try {
      final response = await _apiClient.get(ApiConstants.rooms);

      if (kDebugMode) {
        print('Available rooms response: $response');
      }

      // Extract rooms data from response
      List<dynamic> roomsData = [];
      if (response.containsKey('items')) {
        roomsData = response['items'] as List<dynamic>;
      } else if (response.containsKey('data')) {
        roomsData = response['data'] as List<dynamic>;
      } else if (response.containsKey('rooms')) {
        roomsData = response['rooms'] as List<dynamic>;
      } else {
        // If response has no recognized wrapper, assume it's a direct list
        roomsData = response as List<dynamic>;
      }

      return roomsData
          .map((roomData) => Room.fromJson(roomData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available rooms: $e');
      }
      rethrow;
    }
  }

  // Create a new room
  Future<Room> createRoom({
    required String name,
    int maxPlayers = 8,
    int maxRounds = 3,
    int drawingTimeSeconds = 80,
    bool isPrivate = false,
    String? password,
    bool useAI = false,
  }) async {
    try {
      final data = {
        'name': name,
        'max_players': maxPlayers,
        'max_rounds': maxRounds,
        'drawing_time_seconds': drawingTimeSeconds,
        'is_private': isPrivate,
        'use_ai': useAI,
      };

      if (isPrivate && password != null) {
        data['password'] = password;
      }

      final response = await _apiClient.post(ApiConstants.rooms, data: data);

      final room = Room.fromJson(response);
      _roomUpdatesController.add(room);
      return room;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating room: $e');
      }
      rethrow;
    }
  }

  // Join a room
  Future<Room> joinRoom(String roomId, {String? password}) async {
    try {
      final endpoint = ApiConstants.joinRoom(roomId);

      final data =
          password != null ? {'password': password} : <String, dynamic>{};

      final response = await _apiClient.post(endpoint, data: data);

      final room = Room.fromJson(response);
      _roomUpdatesController.add(room);

      // Connect to WebSocket after joining
      _connectToRoomWebSocket(roomId);

      return room;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining room: $e');
      }
      rethrow;
    }
  }

  // Leave a room
  Future<void> leaveRoom(String roomId) async {
    try {
      final endpoint = ApiConstants.leaveRoom(roomId);

      await _apiClient.post(endpoint);

      // Disconnect WebSocket
      _disconnectFromRoomWebSocket();
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving room: $e');
      }
      rethrow;
    }
  }

  // Update room settings
  Future<Room> updateRoomSettings({
    required String roomId,
    String? name,
    int? maxPlayers,
    int? maxRounds,
    int? drawingTimeSeconds,
    bool? isPrivate,
    String? password,
    bool? useAI,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (maxPlayers != null) data['max_players'] = maxPlayers;
      if (maxRounds != null) data['max_rounds'] = maxRounds;
      if (drawingTimeSeconds != null)
        data['drawing_time_seconds'] = drawingTimeSeconds;
      if (isPrivate != null) data['is_private'] = isPrivate;
      if (password != null) data['password'] = password;
      if (useAI != null) data['use_ai'] = useAI;

      final response = await _apiClient.patch(
        '${ApiConstants.rooms}/$roomId',
        data: data,
      );

      final room = Room.fromJson(response);
      _roomUpdatesController.add(room);
      return room;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating room settings: $e');
      }
      rethrow;
    }
  }

  // Toggle player ready status
  Future<void> toggleReady(String roomId, bool isReady) async {
    try {
      final endpoint = ApiConstants.readyStatus(roomId);

      await _apiClient.post(endpoint, data: {'is_ready': isReady});
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling ready status: $e');
      }
      rethrow;
    }
  }

  // Start a game
  Future<Map<String, dynamic>> startGame(String roomId) async {
    try {
      final endpoint = ApiConstants.startGame(roomId);

      final response = await _apiClient.post(endpoint);

      if (response.containsKey('state')) {
        // Handle game state update if provided
        _handleGameStateUpdate(response['state'] as Map<String, dynamic>);
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting game: $e');
      }
      rethrow;
    }
  }

  // Select a word for the round
  Future<Map<String, dynamic>> selectWord(String roomId, String word) async {
    try {
      final endpoint = ApiConstants.selectWord(roomId);

      final response = await _apiClient.post(endpoint, data: {'word': word});

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error selecting word: $e');
      }
      rethrow;
    }
  }

  // Submit a guess
  Future<Map<String, dynamic>> submitGuess(String roomId, String guess) async {
    try {
      final endpoint = ApiConstants.submitGuess(roomId);

      final response = await _apiClient.post(endpoint, data: {'guess': guess});

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting guess: $e');
      }
      rethrow;
    }
  }

  // End current round
  Future<Map<String, dynamic>> endRound(String roomId) async {
    try {
      final endpoint = ApiConstants.endRound(roomId);

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending round: $e');
      }
      rethrow;
    }
  }

  // Start next round
  Future<Map<String, dynamic>> startNextRound(String roomId) async {
    try {
      final endpoint = ApiConstants.nextRound(roomId);

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting next round: $e');
      }
      rethrow;
    }
  }

  // End game
  Future<Map<String, dynamic>> endGame(String roomId) async {
    try {
      final endpoint = ApiConstants.endGame(roomId);

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending game: $e');
      }
      rethrow;
    }
  }

  // Get game state
  Future<Map<String, dynamic>> getGameState(String roomId) async {
    try {
      final endpoint = ApiConstants.gameState(roomId);

      final response = await _apiClient.get(endpoint);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting game state: $e');
      }
      rethrow;
    }
  }

  // Connect to WebSocket for real-time updates
  void _connectToRoomWebSocket(String roomId) {
    _wsService = WebSocketService(roomId: roomId);
    _wsService!.connect();

    // Setup listeners for various update types
    _wsService!.drawingUpdates.listen(_handleDrawingUpdate);
    _wsService!.gameStateUpdates.listen(_handleGameStateUpdate);
    _wsService!.chatMessages.listen(_handleChatMessages);
  }

  void _handleDrawingUpdate(Map<String, dynamic> data) {
    // Drawing updates are handled separately by the drawing bloc
  }

  void _handleGameStateUpdate(Map<String, dynamic> data) {
    if (data.containsKey('room')) {
      try {
        final roomData = data['room'] as Map<String, dynamic>;
        final room = Room.fromJson(roomData);
        _roomUpdatesController.add(room);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing room update: $e');
        }
      }
    }

    if (data.containsKey('round')) {
      try {
        final roundData = data['round'] as Map<String, dynamic>;
        final round = GameRound.fromJson(roundData);
        _roundUpdatesController.add(round);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing round update: $e');
        }
      }
    }
  }

  void _handleChatMessages(Map<String, dynamic> data) {
    if (data.containsKey('messages')) {
      try {
        final messagesData = data['messages'] as List<dynamic>;
        final messages =
            messagesData
                .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
                .toList();
        _messageUpdatesController.add(messages);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing chat messages: $e');
        }
      }
    }
  }

  // Disconnect from WebSocket
  void _disconnectFromRoomWebSocket() {
    _wsService?.disconnect();
    _wsService = null;
  }

  // Get the WebSocket service
  WebSocketService? get webSocketService => _wsService;

  // Stream getters from WebSocket
  Stream<Map<String, dynamic>>? get chatMessages => _wsService?.chatMessages;
  Stream<Map<String, dynamic>>? get drawingUpdates =>
      _wsService?.drawingUpdates;
  Stream<Map<String, dynamic>>? get gameStateUpdates =>
      _wsService?.gameStateUpdates;
  Stream<Map<String, dynamic>>? get userUpdates => _wsService?.userUpdates;
  Stream<Map<String, dynamic>>? get errors => _wsService?.errors;
  Stream<bool>? get connectionStatus => _wsService?.connectionStatus;

  // Stream getters needed by GameBloc
  Stream<Room> getRoomUpdates(String roomId) {
    return _roomUpdatesController.stream;
  }

  Stream<GameRound> getRoundUpdates(String roomId) {
    return _roundUpdatesController.stream;
  }

  Stream<List<Message>> getMessageUpdates(String roomId) {
    return _messageUpdatesController.stream;
  }

  // Cleanup
  void dispose() {
    _disconnectFromRoomWebSocket();
    _roomUpdatesController.close();
    _roundUpdatesController.close();
    _messageUpdatesController.close();
  }
}
