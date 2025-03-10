import 'package:wms/models/group.dart';
import 'package:wms/services/group_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с группами через GroupAPIService.
class GroupRepository {
  final GroupAPIService groupAPIService;
  final SessionManager _sessionManager;

  GroupRepository({GroupAPIService? groupAPIService, required String baseUrl})
      : groupAPIService = groupAPIService ?? GroupAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех групп.
  Future<List<Group>> getAllGroups() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> groupMaps = await groupAPIService.getAllGroups();
    return groupMaps.map((map) => Group.fromJson(map)).toList();
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    await _sessionManager.validateSession();
    return await groupAPIService.getGroupById(groupId);
  }

  /// Создает новую группу.
  Future<String> createGroup(Group group) async {
    await _sessionManager.validateSession();
    return await groupAPIService.createGroup(group.toJson());
  }

  /// Обновляет данные группы.
  Future<String> updateGroup(Group group) async {
    await _sessionManager.validateSession();
    return await groupAPIService.updateGroup(group.toJson(), group.groupID);
  }

  /// Удаляет группу по её ID.
  Future<String> deleteGroup(int groupID) async {
    await _sessionManager.validateSession();
    return await groupAPIService.deleteGroup(groupID);
  }
}
