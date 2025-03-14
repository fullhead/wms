import 'package:wms/core/constants.dart';
import 'package:wms/models/group.dart';
import 'package:wms/repositories/group_repository.dart';

/// Презентер для управления группами.
class GroupPresenter {
  final GroupRepository _groupRepository;

  GroupPresenter({GroupRepository? groupRepository})
      : _groupRepository = groupRepository ??
      GroupRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Получает список всех групп.
  Future<List<Group>> fetchAllGroups() async {
    return await _groupRepository.getAllGroups();
  }

  /// Получает группу по её ID.
  Future<Group> fetchGroupById(int groupId) async {
    return await _groupRepository.getGroupById(groupId);
  }

  /// Создает новую группу.
  Future<String> createGroup({
    required String groupName,
    required String groupAccessLevel,
    bool groupStatus = true,
  }) async {
    final group = Group(
      groupID: 0,
      groupName: groupName,
      groupAccessLevel: groupAccessLevel,
      groupStatus: groupStatus,
      groupCreationDate: DateTime.now(),
    );
    return await _groupRepository.createGroup(group);
  }

  /// Обновляет данные группы.
  Future<String> updateGroup(
      Group group, {
        String? name,
        String? accessLevel,
        bool? status,
      }) async {
    if (name != null) group.groupName = name;
    if (accessLevel != null) group.groupAccessLevel = accessLevel;
    if (status != null) group.groupStatus = status;
    return await _groupRepository.updateGroup(group);
  }

  /// Удаляет группу.
  Future<String> deleteGroup(Group group) async {
    return await _groupRepository.deleteGroup(group.groupID);
  }
}
