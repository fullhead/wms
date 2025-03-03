import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/services/user_api_service.dart';
import 'package:wms/services/group_api_service.dart';

/// Репозиторий для работы с пользователями через UserAPIService и GroupAPIService.
class UserRepository {
  final UserAPIService userAPIService;
  final GroupAPIService groupAPIService;

  UserRepository({
    UserAPIService? userAPIService,
    GroupAPIService? groupAPIService,
  })  : userAPIService = userAPIService ??
            UserAPIService(baseUrl: AppConstants.apiBaseUrl),
        groupAPIService = groupAPIService ??
            GroupAPIService(baseUrl: AppConstants.apiBaseUrl);

  /// Получает список всех пользователей.
  Future<List<User>> getAllUsers() async {
    final List<Map<String, dynamic>> userMaps =
        await userAPIService.getAllUsers();
    List<User> users = [];
    // Для каждого пользователя запрашиваем данные группы через GroupAPIService.
    for (var map in userMaps) {
      int groupId = map['GroupID'];
      final Group group = await groupAPIService.getGroupById(groupId);
      users.add(User.fromJson(map, group));
    }
    return users;
  }

  /// Получает пользователя по его ID.
  Future<User> getUserById(int userId) async {
    final Map<String, dynamic> userMap =
        await userAPIService.getUserById(userId);
    int groupId = userMap['GroupID'] ?? 0;
    final Group group = await groupAPIService.getGroupById(groupId);
    return User.fromJson(userMap, group);
  }

  /// Создает нового пользователя.
  Future<String> createUser(User user) async {
    return await userAPIService.createUser(user.toJson());
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(User user) async {
    return await userAPIService.updateUser(user.toJson(), user.userID);
  }

  /// Удаляет пользователя по его ID.
  Future<String> deleteUser(int userID) async {
    return await userAPIService.deleteUser(userID);
  }
}
