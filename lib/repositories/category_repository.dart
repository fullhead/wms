import 'package:wms/models/category.dart' as wms_category;
import 'package:wms/services/category_api_service.dart';
import 'package:wms/core/constants.dart';

/// Репозиторий для работы с категориями через CategoryAPIService.
class CategoryRepository {
  final CategoryAPIService categoryAPIService;

  CategoryRepository({CategoryAPIService? categoryAPIService})
      : categoryAPIService = categoryAPIService ??
            CategoryAPIService(baseUrl: AppConstants.apiBaseUrl);

  /// Получает список всех категорий.
  Future<List<wms_category.Category>> getAllCategory() async {
    final List<Map<String, dynamic>> categoryMaps =
        await categoryAPIService.getAllCategory();
    return categoryMaps
        .map((map) => wms_category.Category.fromJson(map))
        .toList();
  }

  /// Получает категорию по её ID.
  Future<wms_category.Category> getCategoryById(int categoryId) async {
    return await categoryAPIService.getCategoryById(categoryId);
  }

  /// Создает новую категорию.
  Future<void> createCategory(wms_category.Category category) async {
    await categoryAPIService.createCategory(category.toJson());
  }

  /// Обновляет данные категории.
  Future<void> updateCategory(wms_category.Category category) async {
    await categoryAPIService.updateCategory(
        category.toJson(), category.categoryID);
  }

  /// Удаляет категорию по её ID.
  Future<void> deleteCategory(int categoryID) async {
    await categoryAPIService.deleteCategory(categoryID);
  }
}
