import 'package:wms/core/constants.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/services/auth_storage.dart';

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

      if (response.containsKey('error')) {
        throw response['error'];
      }

      if (response.containsKey('token')) {
        final token = response['token'] as String;
        await AuthStorage.saveToken(token);

        final userID = response['userID']?.toString() ?? '';
        await AuthStorage.saveUserID(userID);
      } else {
        throw 'Токен не получен';
      }
    } catch (e) {
      rethrow;
    }
  }
}
