class ApiConstants {
  // Base URL - change this to your backend server URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // For iOS simulator
  // static const String baseUrl = 'https://your-deployed-backend.com';  // Production

  // WebSocket URL - Derive from baseUrl by replacing http with ws
  static String get wsUrl => 'ws${baseUrl.substring(4)}';

  // Auth endpoints
  static const String login = '/api/login';
  static const String currentUser = '/api/users/me';

  // Room endpoints
  static const String rooms = '/api/rooms';
  static String joinRoom(String roomId) => '/api/rooms/$roomId/join';
  static String leaveRoom(String roomId) => '/api/rooms/$roomId/leave';
  static String readyStatus(String roomId) => '/api/rooms/$roomId/ready';
  static String roomWebSocket(String roomId) => '$wsUrl/ws/room/$roomId';

  // Game endpoints
  static String startGame(String roomId) => '/api/games/rooms/$roomId/start';
  static String selectWord(String roomId) =>
      '/api/games/rooms/$roomId/select-word';
  static String submitGuess(String roomId) => '/api/games/rooms/$roomId/guess';
  static String gameState(String roomId) => '/api/games/rooms/$roomId/state';
  static String nextRound(String roomId) =>
      '/api/games/rooms/$roomId/next-round';
  static String endGame(String roomId) => '/api/games/rooms/$roomId/end-game';
  static String endRound(String roomId) => '/api/games/rooms/$roomId/end-round';

  // Drawing endpoints
  static String updateDrawing(String roomId) =>
      '/api/drawings/rooms/$roomId/update';
  static const String generateAiDrawing = '/api/drawings/ai-generate';

  // Leaderboard endpoint
  static const String leaderboard = '/api/leaderboard';

  // Helper function to replace roomId in URL
  static String replaceRoomId(String url, String roomId) {
    return url.replaceAll('{roomId}', roomId);
  }
}
