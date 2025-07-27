class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8000'; // Configurar para produção
  static String? userToken; // Será definido pelo auth service
  static String? currentUserId; // Será definido pelo auth service
  static String? currentUserName; // Será definido pelo auth service
  
  // Método para definir dados do usuário autenticado
  static void setUserData({
    required String token,
    required String userId,
    required String userName,
  }) {
    userToken = token;
    currentUserId = userId;
    currentUserName = userName;
  }
  
  // Método para limpar dados do usuário (logout)
  static void clearUserData() {
    userToken = null;
    currentUserId = null;
    currentUserName = null;
  }
} 