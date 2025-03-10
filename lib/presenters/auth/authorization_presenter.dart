import 'package:wms/core/constants.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Презентер для управления авторизацией.
class AuthorizationPresenter {
  final UserAPIService _userAPIService;

  AuthorizationPresenter({UserAPIService? userAPIService})
      : _userAPIService =
      userAPIService ?? UserAPIService(baseUrl: AppConstants.apiBaseUrl);

  Future<void> login(String username, String password) async {
    final credentials = {'username': username, 'password': password};
    try {
      final response = await _userAPIService.loginUser(credentials);

      // Если вам нужно бросать именно ApiException, можно делать так:
      if (response.containsKey('error')) {
        throw ApiException(response['error']);
      }

      // Ожидаем наличие accessToken и refreshToken в ответе
      if (response.containsKey('accessToken') && response.containsKey('refreshToken')) {
        final accessToken = response['accessToken'] as String;
        final refreshToken = response['refreshToken'] as String;
        await AuthStorage.saveAccessToken(accessToken);
        await AuthStorage.saveRefreshToken(refreshToken);

        final userID = response['userID']?.toString() ?? '';
        final userGroup = response['userGroup']?.toString() ?? '';
        await AuthStorage.saveUserID(userID);
        await AuthStorage.saveUserGroup(userGroup);
      } else {
        throw 'Токены не получены';
      }
    } catch (e) {
      rethrow;
    }
  }
}
