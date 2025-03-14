import 'package:wms/models/issue.dart';
import 'package:wms/models/product.dart';
import 'package:wms/services/issue_api_service.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';
import 'package:wms/services/cell_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с выдачей через IssueAPIService, ProductAPIService,
/// CategoryAPIService и CellAPIService.
class IssueRepository {
  final IssueAPIService issueAPIService;
  final ProductAPIService productAPIService;
  final CategoryAPIService categoryAPIService;
  final CellAPIService cellAPIService;
  final SessionManager _sessionManager;

  IssueRepository({
    IssueAPIService? issueAPIService,
    ProductAPIService? productAPIService,
    CategoryAPIService? categoryAPIService,
    CellAPIService? cellAPIService,
    required String baseUrl,
  })  : issueAPIService =
      issueAPIService ?? IssueAPIService(baseUrl: baseUrl),
        productAPIService =
            productAPIService ?? ProductAPIService(baseUrl: baseUrl),
        categoryAPIService =
            categoryAPIService ?? CategoryAPIService(baseUrl: baseUrl),
        cellAPIService = cellAPIService ?? CellAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех записей выдачи.
  Future<List<Issue>> getAllIssues() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> issueMaps =
    await issueAPIService.getAllIssues();
    List<Issue> issues = [];
    for (var map in issueMaps) {
      int productId = map['ProductID'] ?? 0;
      int cellId = map['CellID'] ?? 0;
      final productMap = await productAPIService.getProductById(productId);
      int categoryId = productMap['CategoryID'] ?? 0;
      final category = await categoryAPIService.getCategoryById(categoryId);
      Product product = Product.fromJson(productMap, category);
      final cell = await cellAPIService.getCellById(cellId);
      issues.add(Issue.fromJson(map, product: product, cell: cell));
    }
    return issues;
  }

  /// Получает запись выдачи по её ID.
  Future<Issue> getIssueById(int issueId) async {
    await _sessionManager.validateSession();
    final Map<String, dynamic> issueMap =
    await issueAPIService.getIssueById(issueId);
    int productId = issueMap['ProductID'] ?? 0;
    int cellId = issueMap['CellID'] ?? 0;
    final productMap = await productAPIService.getProductById(productId);
    int categoryId = productMap['CategoryID'] ?? 0;
    final category = await categoryAPIService.getCategoryById(categoryId);
    Product product = Product.fromJson(productMap, category);
    final cell = await cellAPIService.getCellById(cellId);
    return Issue.fromJson(issueMap, product: product, cell: cell);
  }

  /// Создает новую запись выдачи.
  Future<String> createIssue(Issue issue) async {
    await _sessionManager.validateSession();
    return await issueAPIService.createIssue(issue.toJson());
  }

  /// Обновляет запись выдачи.
  Future<String> updateIssue(Issue issue) async {
    await _sessionManager.validateSession();
    return await issueAPIService.updateIssue(issue.toJson(), issue.issueID);
  }

  /// Удаляет запись выдачи по её ID.
  Future<String> deleteIssue(int issueId) async {
    await _sessionManager.validateSession();
    return await issueAPIService.deleteIssue(issueId);
  }
}
