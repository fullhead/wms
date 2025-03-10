import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/services/group_api_service.dart';
import 'package:wms/core/session/session_manager.dart';


/// Репозиторий для работы с пользователями через UserAPIService и GroupAPIService.
class UserRepository {
  final UserAPIService userAPIService;
  final GroupAPIService groupAPIService;
  final SessionManager _sessionManager;

  UserRepository({
    UserAPIService? userAPIService,
    GroupAPIService? groupAPIService,
    required String baseUrl,
  })  : userAPIService = userAPIService ?? UserAPIService(baseUrl: baseUrl),
        groupAPIService = groupAPIService ?? GroupAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех пользователей.
  Future<List<User>> getAllUsers() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> userMaps = await userAPIService.getAllUsers();
    List<User> users = [];
    for (var map in userMaps) {
      int groupId = map['GroupID'];
      final Group group = await groupAPIService.getGroupById(groupId);
      users.add(User.fromJson(map, group));
    }
    return users;
  }

  /// Получает пользователя по его ID.
  Future<User> getUserById(int userId) async {
    await _sessionManager.validateSession();
    final Map<String, dynamic> userMap = await userAPIService.getUserById(userId);
    int groupId = userMap['GroupID'] ?? 0;
    final Group group = await groupAPIService.getGroupById(groupId);
    return User.fromJson(userMap, group);
  }

  /// Создает нового пользователя.
  Future<String> createUser(User user, {String? avatarFilePath}) async {
    await _sessionManager.validateSession();
    return await userAPIService.createUser(user.toJson(), avatarFilePath: avatarFilePath);
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(User user) async {
    await _sessionManager.validateSession();
    return await userAPIService.updateUser(user.toJson(), user.userID);
  }

  /// Удаляет пользователя по его ID.
  Future<String> deleteUser(int userID) async {
    await _sessionManager.validateSession();
    return await userAPIService.deleteUser(userID);
  }

  /// Устанавливает новый аватар для пользователя.
  Future<String> setUserAvatar(int userId, String imagePath) async {
    await _sessionManager.validateSession();
    return await userAPIService.setUserAvatar(userId, imagePath);
  }

  /// Получает URL аватара пользователя.
  Future<String> getUserAvatar(int userId) async {
    await _sessionManager.validateSession();
    return await userAPIService.getUserAvatar(userId);
  }

  /// Удаляет аватар пользователя.
  Future<String> deleteUserAvatar(int userId) async {
    await _sessionManager.validateSession();
    return await userAPIService.deleteUserAvatar(userId);
  }
}
