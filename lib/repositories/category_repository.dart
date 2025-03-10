import 'package:wms/models/category.dart';
import 'package:wms/services/category_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с категориями через CategoryAPIService.
class CategoryRepository {
  final CategoryAPIService categoryAPIService;
  final SessionManager _sessionManager;

  CategoryRepository({CategoryAPIService? categoryAPIService, required String baseUrl})
      : categoryAPIService = categoryAPIService ?? CategoryAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех категорий.
  Future<List<Category>> getAllCategory() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> categoryMaps = await categoryAPIService.getAllCategory();
    return categoryMaps.map((map) => Category.fromJson(map)).toList();
  }

  /// Получает категорию по её ID.
  Future<Category> getCategoryById(int categoryId) async {
    await _sessionManager.validateSession();
    return await categoryAPIService.getCategoryById(categoryId);
  }

  /// Создает новую категорию.
  Future<String> createCategory(Category category) async {
    await _sessionManager.validateSession();
    return await categoryAPIService.createCategory(category.toJson());
  }

  /// Обновляет данные категории.
  Future<String> updateCategory(Category category) async {
    await _sessionManager.validateSession();
    return await categoryAPIService.updateCategory(category.toJson(), category.categoryID);
  }

  /// Удаляет категорию по её ID.
  Future<String> deleteCategory(int categoryID) async {
    await _sessionManager.validateSession();
    return await categoryAPIService.deleteCategory(categoryID);
  }
}
