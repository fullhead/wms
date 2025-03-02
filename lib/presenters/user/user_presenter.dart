import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/repositories/user_repository.dart';
import 'package:wms/services/api_service.dart';


/// Презентер для управления пользователями.
class UserPresenter {
  final UserRepository _userRepository;

  UserPresenter({UserRepository? userRepository})
      : _userRepository = userRepository ??
            UserRepository(
                apiService: APIService(baseUrl: AppConstants.apiBaseUrl));

  /// Получает список всех пользователей.
  Future<List<User>> fetchAllUsers() async {
    return await _userRepository.getAllUsers();
  }

  /// Создаёт нового пользователя.
  Future<void> createUser({
    required String fullName,
    required String username,
    required String password,
    required Group group,
    String avatar = '',
    bool status = true,
  }) async {
    final newUser = User(
      userID: 0,
      userFullname: fullName,
      userName: username,
      userPassword: password,
      userGroup: group,
      userAvatar: avatar,
      userStatus: status,
      userCreationDate: DateTime.now(),
      userLastLoginDate: DateTime.now(),
    );
    await _userRepository.createUser(newUser);
  }

  /// Обновляет данные пользователя.
  Future<void> updateUser(
    User user, {
    String? fullName,
    String? username,
    String? avatar,
    bool? status,
    String? password,
    Group? group,
  }) async {
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
    await _userRepository.updateUser(user);
  }

  /// Удаляет пользователя.
  Future<void> deleteUser(User user) async {
    await _userRepository.deleteUser(user.userID);
  }
}
