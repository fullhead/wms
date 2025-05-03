import 'package:wms/core/constants.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/issue.dart';
import 'package:wms/models/product.dart';
import 'package:wms/repositories/issue_repository.dart';
import 'package:wms/services/issue_api_service.dart';

/// Презентер для управления выдачей.
class IssuePresenter {
  final IssueRepository _repo =
  IssueRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Доступ к API-сервису (если нужен напрямую).
  IssueAPIService get api => _repo.api;

  /// Получает список всех записей выдачи с деталями.
  Future<List<Issue>> fetchAllIssue() => _repo.getAllIssues();

  /// Получает запись выдачи по ID с деталями.
  Future<Issue> getIssueById(int id) => _repo.getIssueById(id);

  /// Создаёт новую запись выдачи.
  Future<String> createIssue({
    required Product product,
    required Cell cell,
    required int issueQuantity,
    required DateTime issueDate,
  }) =>
      _repo.createIssue(
        Issue(
          issueID: 0,
          product: product,
          cell: cell,
          issueQuantity: issueQuantity,
          issueDate: issueDate,
        ),
      );

  /// Обновляет существующую запись выдачи.
  Future<String> updateIssue(
      Issue issue, {
        Product? product,
        Cell? cell,
        int? issueQuantity,
        DateTime? issueDate,
      }) {
    if (product != null) issue.product = product;
    if (cell != null) issue.cell = cell;
    if (issueQuantity != null) issue.issueQuantity = issueQuantity;
    if (issueDate != null) issue.issueDate = issueDate;
    return _repo.updateIssue(issue);
  }

  /// Удаляет запись выдачи по ID.
  Future<String> deleteIssue(Issue issue) => _repo.deleteIssue(issue.issueID);
}
