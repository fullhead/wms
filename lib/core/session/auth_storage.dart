import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  // Ключи для хранения данных
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _userGroupIdKey = 'auth_user_group_id';
  static const _userAvatarKey = 'user_avatar';

  /// Методы для access token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  /// Методы для refresh token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Методы для userID
  static Future<void> saveUserID(String userID) async {
    await _storage.write(key: _userIdKey, value: userID);
  }

  static Future<String?> getUserID() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> deleteUserID() async {
    await _storage.delete(key: _userIdKey);
  }

  /// Методы для userUserGroup
  static Future<void> saveUserGroup(String groupID) async {
    await _storage.write(key: _userGroupIdKey, value: groupID);
  }

  static Future<String?> getUserGroup() async {
    return await _storage.read(key: _userGroupIdKey);
  }

  static Future<void> deleteUserGroup() async {
    await _storage.delete(key: _userGroupIdKey);
  }

  /// Методы для URL аватара пользователя
  static Future<void> saveUserAvatar(String avatarUrl) async {
    await _storage.write(key: _userAvatarKey, value: avatarUrl);
  }

  static Future<String?> getUserAvatar() async {
    return await _storage.read(key: _userAvatarKey);
  }

  static Future<void> deleteUserAvatar() async {
    await _storage.delete(key: _userAvatarKey);
  }

  /// Очистить все данные авторизации.
  static Future<void> clearSession() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserID();
    await deleteUserGroup();
    await deleteUserAvatar();
  }
}
