class ApiConstants {
  // Base URL - change this to your backend server URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // For iOS simulator
  // static const String baseUrl = 'https://your-deployed-backend.com';  // Production

  // WebSocket URL
  static String wsUrl = 'ws${baseUrl.substring(4)}/ws';

  // API Endpoints
  static const String login = '/api/login';
  static const String currentUser = '/api/users/me';

  // Room Endpoints
  static const String rooms = '/api/rooms';
  static const String joinRoom = '/api/rooms/{roomId}/join';
  static const String leaveRoom = '/api/rooms/{roomId}/leave';
  static const String readyStatus = '/api/rooms/{roomId}/ready';

  // Game Endpoints
  static const String startGame = '/api/games/rooms/{roomId}/start';
  static const String selectWord = '/api/games/rooms/{roomId}/select-word';
  static const String submitGuess = '/api/games/rooms/{roomId}/guess';
  static const String gameState = '/api/games/rooms/{roomId}/state';
  static const String nextRound = '/api/games/rooms/{roomId}/next-round';
  static const String endGame = '/api/games/rooms/{roomId}/end-game';

  // Drawing Endpoints
  static const String updateDrawing = '/api/drawings/rooms/{roomId}/update';
  static const String generateAiDrawing = '/api/drawings/ai-generate';

  // WebSocket Endpoint
  static String roomWebSocket(String roomId) => '${wsUrl}/room/$roomId';

  // Replace URL params
  static String replaceRoomId(String url, String roomId) {
    return url.replaceAll('{roomId}', roomId);
  }
}
