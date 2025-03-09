import '../models/game_round.dart';
import '../models/message.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';
import 'room_service.dart';

class GameService {
  final ApiClient _apiClient = ApiClient();
  final RoomService _roomService = RoomService();

  // Start a game - delegates to room service to maintain compatibility with GameBloc
  Future<Map<String, dynamic>> startGame(String roomId) async {
    return _roomService.startGame(roomId);
  }

  // Select a word for the round - delegates to room service
  Future<Map<String, dynamic>> selectWord(String roomId, String word) async {
    return _roomService.selectWord(roomId, word);
  }

  // Submit a guess - delegates to room service
  Future<Map<String, dynamic>> submitGuess(String roomId, String guess) async {
    return _roomService.submitGuess(roomId, guess);
  }

  // Get current game state
  Future<Map<String, dynamic>> getGameState(String roomId) async {
    try {
      final endpoint = ApiConstants.replaceRoomId(
        ApiConstants.gameState,
        roomId,
      );

      final response = await _apiClient.get(endpoint);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // End the current round
  Future<Map<String, dynamic>> endRound(String roomId) async {
    try {
      final endpoint = ApiConstants.replaceRoomId(
        '/api/games/rooms/{roomId}/end-round',
        roomId,
      );

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Start the next round
  Future<Map<String, dynamic>> startNextRound(String roomId) async {
    try {
      final endpoint = ApiConstants.replaceRoomId(
        ApiConstants.nextRound,
        roomId,
      );

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // End the game
  Future<Map<String, dynamic>> endGame(String roomId) async {
    try {
      final endpoint = ApiConstants.replaceRoomId(ApiConstants.endGame, roomId);

      final response = await _apiClient.post(endpoint);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Send a game action via WebSocket
  void sendGameAction(String roomId, String action, Map<String, dynamic> data) {
    final wsService = _roomService.webSocketService;

    if (wsService != null) {
      wsService.sendGameAction(action, data);
    }
  }

  // Send a chat message via WebSocket
  void sendChatMessage(String roomId, String content) {
    final wsService = _roomService.webSocketService;

    if (wsService != null) {
      wsService.sendChatMessage(content);
    }
  }

  // Provide access to room service streams for compatibility with GameBloc
  Stream<GameRound> getRoundUpdates(String roomId) {
    return _roomService.getRoundUpdates(roomId);
  }

  Stream<List<Message>> getMessageUpdates(String roomId) {
    return _roomService.getMessageUpdates(roomId);
  }
}
