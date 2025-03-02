import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  // Экземпляр SecureStorage
  static const _storage = FlutterSecureStorage();

  // Ключи, под которыми будем хранить данные
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  /// Сохранить токен
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Прочитать токен
  static Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token;
  }

  /// Удалить токен
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Сохранить userID (если нужно)
  static Future<void> saveUserID(String userID) async {
    await _storage.write(key: _userIdKey, value: userID);
  }

  /// Прочитать userID
  static Future<String?> getUserID() async {
    final userID = await _storage.read(key: _userIdKey);
    return userID;
  }

  /// Удалить userID
  static Future<void> deleteUserID() async {
    await _storage.delete(key: _userIdKey);
  }
}
