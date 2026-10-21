import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyDriverId = 'driver_id';
  static const String _keyUserRole = 'user_role';

  // Salva os dados de sessão do usuário após o login
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
    String? driverId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserRole, role);

    if (driverId != null) {
      await prefs.setString(_keyDriverId, driverId);
    }
  }

  // Obtém o token JWT salvo
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Obtém o driverId salvo (se for motorista)
  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverId);
  }

  // Limpa os dados ao fazer Logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}