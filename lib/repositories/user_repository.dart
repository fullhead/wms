import 'package:wms/models/user.dart';
import 'package:wms/services/api_service.dart';

/// Репозиторий для работы с пользователями через REST API.
class UserRepository {
  final APIService apiService;

  UserRepository({required this.apiService});

  /// Получает список всех пользователей.
  Future<List<User>> getAllUsers() async {
    final List<Map<String, dynamic>> userMaps = await apiService.getAllUsers();
    List<User> users = [];
    for (var map in userMaps) {
      int groupId = map['GroupID'];
      final group = await apiService.getGroupById(groupId);
      users.add(User.fromJson(map, group));
    }
    return users;
  }

  /// Создаёт нового пользователя.
  Future<void> createUser(User user) async {
    await apiService.createUser(user.toJson());
  }

  /// Обновляет данные пользователя.
  Future<void> updateUser(User user) async {
    await apiService.updateUser(user.toJson(), user.userID);
  }

  /// Удаляет пользователя по ID.
  Future<void> deleteUser(int userID) async {
    await apiService.deleteUser(userID);
  }
}
