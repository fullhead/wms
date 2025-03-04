import 'package:wms/models/user.dart';
import 'package:wms/repositories/user_repository.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/services/session_manager.dart';
import 'package:wms/presenters/user/user_presenter.dart';

/// Презентер для управления персональными данными пользователя (профилем).
class PersonalizationPresenter {
  final UserPresenter _userPresenter;
  final SessionManager _sessionManager;
  final UserRepository _userRepository;

  PersonalizationPresenter({
    UserPresenter? userPresenter,
    SessionManager? sessionManager,
    UserRepository? userRepository,
  })  : _userPresenter = userPresenter ?? UserPresenter(),
        _sessionManager = sessionManager ?? SessionManager(),
        _userRepository = userRepository ?? UserRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Получает профиль текущего пользователя по идентификатору, сохранённому в сессии.
  Future<User> getCurrentUser() async {
    final userIDStr = await _sessionManager.getCurrentUserID();
    if (userIDStr == null) {
      throw Exception("Пользователь не авторизован");
    }
    final userID = int.tryParse(userIDStr);
    if (userID == null) {
      throw Exception("Некорректный идентификатор пользователя");
    }
    return await _userRepository.getUserById(userID);
  }

  /// Обновляет аватар пользователя.
  /// [avatarImagePath] — путь к новому изображению аватара.
  Future<String> updateAvatar(User user, String avatarImagePath) async {
    final String newAvatarPath =
    await _userPresenter.userApiService.uploadUserAvatar(avatarImagePath);
    // Обновляем поле аватара в объекте пользователя перед вызовом обновления
    user.userAvatar = newAvatarPath;
    return await _userPresenter.updateUser(user);
  }

  /// Обновляет логин пользователя.
  Future<String> updateLogin(User user, String newLogin) async {
    return await _userPresenter.updateUser(user, username: newLogin);
  }

  /// Обновляет пароль пользователя.
  Future<String> updatePassword(User user, String newPassword) async {
    return await _userPresenter.updateUser(user, password: newPassword);
  }

  /// Обновляет сессию пользователя, получая новый токен.
  Future<void> refreshUserSession() async {
    await _sessionManager.refreshSession();
  }
}
