import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/session/access_expired_alert_dialog.dart';

/// Менеджер сессии для работы с состоянием авторизации пользователя.
class SessionManager {
  final UserAPIService _userAPIService;

  SessionManager({UserAPIService? userAPIService})
      : _userAPIService =
      userAPIService ?? UserAPIService(baseUrl: AppConstants.apiBaseUrl);

  /// Возвращает идентификатор текущего пользователя.
  Future<String?> getCurrentUserID() async {
    return await AuthStorage.getUserID();
  }

  /// Обновляет access token, используя refresh token.
  Future<void> refreshSession() async {
    try {
      await AuthStorage.getRefreshToken();
      final newAccessToken = await _userAPIService.refreshToken();
      await AuthStorage.saveAccessToken(newAccessToken);
    } catch (e) {
      await AccessExpiredDialog.showAccessExpired();
      await logout();
      rethrow;
    }
  }

  /// Проверяет валидность access token и обновляет его при необходимости.
  Future<void> validateSession() async {
    final token = await AuthStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Отсутствует разрешение для выполнения операции!');
    }
    if (JwtDecoder.isExpired(token)) {
      try {
        await refreshSession();
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Выполняет logout, очищая все данные авторизации.
  Future<void> logout() async {
    await AuthStorage.clearSession();
  }
}
