import 'package:wms/core/constants.dart';
import 'package:wms/models/issue.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/repositories/issue_repository.dart';
import 'package:wms/services/issue_api_service.dart';
import 'package:wms/services/product_api_service.dart';

/// Презентер для управления выдачей.
class IssuePresenter {
  final IssueRepository _issueRepository;

  IssuePresenter({IssueRepository? issueRepository})
      : _issueRepository = issueRepository ?? IssueRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Геттер для доступа к IssueAPIService.
  IssueAPIService get issueApiService => _issueRepository.issueAPIService;

  /// Геттер для доступа к ProductAPIService.
  ProductAPIService get productApiService => _issueRepository.productAPIService;

  /// Получает список всех записей выдачи.
  Future<List<Issue>> fetchAllIssues() async {
    return await _issueRepository.getAllIssues();
  }

  /// Создает новую запись выдачи.
  Future<String> createIssue({required Product product, required Cell cell, required int issueQuantity, DateTime? issueDate}) async {
    final issue = Issue(
      issueID: 0,
      product: product,
      cell: cell,
      issueQuantity: issueQuantity,
      issueDate: issueDate ?? DateTime.now(),
    );
    return await _issueRepository.createIssue(issue);
  }

  /// Обновляет данные записи выдачи.
  Future<String> updateIssue(Issue issue, {Product? product, Cell? cell, int? issueQuantity, DateTime? issueDate}) async {
    if (product != null) issue.product = product;
    if (cell != null) issue.cell = cell;
    if (issueQuantity != null) issue.issueQuantity = issueQuantity;
    if (issueDate != null) issue.issueDate = issueDate;
    return await _issueRepository.updateIssue(issue);
  }

  /// Удаляет запись выдачи.
  Future<String> deleteIssue(Issue issue) async {
    return await _issueRepository.deleteIssue(issue.issueID);
  }
}
