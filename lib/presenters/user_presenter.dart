import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/repositories/user_repository.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/services/group_api_service.dart';


/// Презентер для управления пользователями.
class UserPresenter {
  final UserRepository _userRepository;

  UserPresenter({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Геттер для доступа к UserAPIService.
  UserAPIService get userApiService => _userRepository.userAPIService;

  /// Геттер для доступа к GroupAPIService.
  GroupAPIService get groupApiService => _userRepository.groupAPIService;

  /// Получает список всех пользователей.
  Future<List<User>> fetchAllUsers() async {
    return await _userRepository.getAllUsers();
  }

  /// Создает нового пользователя.
  Future<String> createUser({required String fullName, required String username, required String password, required Group group, String? avatarFilePath, bool status = true}) async {
    final newUser = User(
      userID: 0,
      userFullname: fullName,
      userName: username,
      userPassword: password,
      userGroup: group,
      userAvatar: '',
      userStatus: status,
      userCreationDate: DateTime.now(),
      userLastLoginDate: DateTime.now(),
    );
    return await _userRepository.createUser(newUser, avatarFilePath: avatarFilePath);
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(User user, {String? fullName, String? username, String? avatar, bool? status, String? password, Group? group}) async {
    if (fullName != null) user.userFullname = fullName;
    if (username != null) user.userName = username;
    if (avatar != null) user.userAvatar = avatar;
    if (status != null) user.userStatus = status;
    if (password != null && password.isNotEmpty) {
      user.userPassword = password;
    }
    if (group != null) {
      user.userGroup = group;
    }
    return await _userRepository.updateUser(user);
  }

  /// Удаляет пользователя.
  Future<String> deleteUser(User user) async {
    return await _userRepository.deleteUser(user.userID);
  }

  /// Устанавливает новый аватар для пользователя.
  Future<String> setUserAvatar(int userId, String imagePath) async {
    return await _userRepository.setUserAvatar(userId, imagePath);
  }

  /// Получает URL аватара пользователя.
  Future<String> getUserAvatar(int userId) async {
    return await _userRepository.getUserAvatar(userId);
  }

  /// Удаляет аватар пользователя.
  Future<String> deleteUserAvatar(int userId) async {
    return await _userRepository.deleteUserAvatar(userId);
  }
}
