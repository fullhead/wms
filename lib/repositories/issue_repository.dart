import 'package:wms/core/session/session_manager.dart';
import 'package:wms/models/issue.dart';
import 'package:wms/services/issue_api_service.dart';

/// Репозиторий для работы с выдачей через IssueAPIService.
class IssueRepository {
  final IssueAPIService api;
  final SessionManager _session = SessionManager();

  IssueRepository({IssueAPIService? apiService, required String baseUrl})
      : api = apiService ?? IssueAPIService(baseUrl: baseUrl);

  /// Получает список всех записей выдачи с деталями.
  Future<List<Issue>> getAllIssues() async {
    await _session.validateSession();
    final maps = await api.getAllIssue();
    return maps.map(Issue.fromJsonWithDetails).toList();
  }

  /// Получает запись выдачи по ID с деталями.
  Future<Issue> getIssueById(int id) async {
    await _session.validateSession();
    final map = await api.getIssueById(id);
    return Issue.fromJsonWithDetails(map);
  }

  /// Создаёт новую запись выдачи.
  Future<String> createIssue(Issue issue) async {
    await _session.validateSession();
    return api.createIssue(issue.toJson());
  }

  /// Обновляет существующую запись выдачи.
  Future<String> updateIssue(Issue issue) async {
    await _session.validateSession();
    return api.updateIssue(issue.toJson(), issue.issueID);
  }

  /// Удаляет запись выдачи по ID.
  Future<String> deleteIssue(int id) async {
    await _session.validateSession();
    return api.deleteIssue(id);
  }
}
