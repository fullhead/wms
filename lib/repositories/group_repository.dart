import 'package:wms/models/group.dart';
import 'package:wms/services/group_api_service.dart';

/// Репозиторий для работы с группами через GroupAPIService.
class GroupRepository {
  final GroupAPIService groupAPIService;

  GroupRepository({GroupAPIService? groupAPIService, required String baseUrl})
      : groupAPIService = groupAPIService ?? GroupAPIService(baseUrl: baseUrl);

  /// Получает список всех групп.
  Future<List<Group>> getAllGroups() async {
    final List<Map<String, dynamic>> groupMaps = await groupAPIService.getAllGroups();
    return groupMaps.map((map) => Group.fromJson(map)).toList();
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    return await groupAPIService.getGroupById(groupId);
  }

  /// Создает новую группу.
  Future<String> createGroup(Group group) async {
    return await groupAPIService.createGroup(group.toJson());
  }

  /// Обновляет данные группы.
  Future<String> updateGroup(Group group) async {
    return await groupAPIService.updateGroup(group.toJson(), group.groupID);
  }

  /// Удаляет группу по её ID.
  Future<String> deleteGroup(int groupID) async {
    return await groupAPIService.deleteGroup(groupID);
  }
}
