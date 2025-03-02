import 'package:wms/models/group.dart';
import 'package:wms/services/api_service.dart';

/// Репозиторий для работы с группами через REST API.
class GroupRepository {
  final APIService apiService;

  GroupRepository({required this.apiService});

  /// Получает список всех групп.
  Future<List<Group>> getAllGroups() async {
    final List<Map<String, dynamic>> groupMaps = await apiService.getAllGroups();
    return groupMaps.map((map) => Group.fromJson(map)).toList();
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    return await apiService.getGroupById(groupId);
  }

  /// Создает новую группу (ID и дату создания не отправляем).
  Future<void> createGroup(Group group) async {
    await apiService.createGroup(group.toJson());
  }

  /// Обновляет данные группы (ID передается отдельно).
  Future<void> updateGroup(Group group) async {
    await apiService.updateGroup(group.toJson(), group.groupID);
  }

  /// Удаляет группу по её ID.
  Future<void> deleteGroup(int groupID) async {
    await apiService.deleteGroup(groupID);
  }
}