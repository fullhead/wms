import 'package:wms/services/auth_storage.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/core/constants.dart';

/// Менеджер сессии для работы с состоянием авторизации пользователя.
class SessionManager {
  final UserAPIService _userAPIService;

  SessionManager({UserAPIService? userAPIService})
      : _userAPIService = userAPIService ?? UserAPIService(baseUrl: AppConstants.apiBaseUrl);

  /// Проверяет, авторизован ли пользователь (наличие токена).
  Future<bool> isLoggedIn() async {
    final token = await AuthStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Возвращает идентификатор текущего пользователя, сохранённый в хранилище.
  Future<String?> getCurrentUserID() async {
    return await AuthStorage.getUserID();
  }

  /// Обновляет токен пользователя, вызывая эндпоинт обновления.
  Future<void> refreshSession() async {
    try {
      final newToken = await _userAPIService.refreshToken();
      await AuthStorage.saveToken(newToken);
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  /// Выполняет выход пользователя, очищая данные авторизации и кэш аватара.
  Future<void> logout() async {
    await AuthStorage.deleteToken();
    await AuthStorage.deleteUserID();
    await AuthStorage.deleteUserAvatar();
  }
}
