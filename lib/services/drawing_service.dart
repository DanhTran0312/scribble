import '../models/drawing.dart';
import '../utils/api_constants.dart';
import 'api_client.dart';
import 'room_service.dart';

class DrawingService {
  final ApiClient _apiClient = ApiClient();
  final RoomService _roomService = RoomService();

  // Update drawing via REST API
  Future<Map<String, dynamic>> updateDrawing(
    String roomId,
    DrawingUpdate drawingUpdate,
  ) async {
    try {
      final endpoint = ApiConstants.replaceRoomId(
        ApiConstants.updateDrawing,
        roomId,
      );

      final response = await _apiClient.post(
        endpoint,
        data: drawingUpdate.toJson(),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generate AI drawing
  Future<Map<String, dynamic>> generateAiDrawing(
    String wordPrompt, {
    String style = 'doodle',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.generateAiDrawing,
        data: {'word_prompt': wordPrompt, 'style': style},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Send drawing update via WebSocket
  void sendDrawingUpdate(String roomId, DrawingUpdate drawingUpdate) {
    final wsService = _roomService.webSocketService;

    if (wsService != null) {
      wsService.sendDrawingUpdate(drawingUpdate.toJson());
    }
  }

  // Get drawing updates stream from WebSocket
  Stream<Map<String, dynamic>>? getDrawingUpdates(String roomId) {
    return _roomService.drawingUpdates;
  }

  // Add stroke to drawing
  void addStroke(String roomId, DrawStroke stroke) {
    sendDrawingUpdate(roomId, DrawingUpdate(addStroke: stroke));
  }

  // Add point to last stroke
  void addPointToLastStroke(String roomId, DrawPoint point) {
    sendDrawingUpdate(roomId, DrawingUpdate(addPointToLastStroke: point));
  }

  // Clear drawing
  void clearDrawing(String roomId) {
    sendDrawingUpdate(roomId, DrawingUpdate(clear: true));
  }

  // Undo last stroke
  void undoLastStroke(String roomId) {
    sendDrawingUpdate(roomId, DrawingUpdate(undoLastStroke: true));
  }
}

class DrawingUpdate {
  final DrawStroke? addStroke;
  final DrawPoint? addPointToLastStroke;
  final bool undoLastStroke;
  final bool clear;

  DrawingUpdate({
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
}
