import 'package:wms/models/category.dart';
import 'package:wms/services/api_service.dart';

/// Репозиторий для работы с категориями через REST API.
class CategoryRepository {
  final APIService apiService;

  CategoryRepository({required this.apiService});

  /// Получает список всех категорий.
  Future<List<Category>> getAllCategory() async {
    final List<Map<String, dynamic>> categoryMaps = await apiService.getAllCategory();
    return categoryMaps.map((map) => Category.fromJson(map)).toList();
  }

  /// Получает категорию по её ID.
  Future<Category> getCategoryById(int categoryId) async {
    return await apiService.getCategoryById(categoryId);
  }

  /// Создает новую категорию.
  Future<void> createCategory(Category category) async {
    await apiService.createCategory(category.toJson());
  }

  /// Обновляет данные категории.
  Future<void> updateCategory(Category category) async {
    await apiService.updateCategory(category.toJson(), category.categoryID);
  }

  /// Удаляет категорию по её ID.
  Future<void> deleteCategory(int categoryID) async {
    await apiService.deleteCategory(categoryID);
  }
}
