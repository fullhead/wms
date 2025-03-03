import 'package:wms/core/constants.dart';
import 'package:wms/models/category.dart' as wms_category;
import 'package:wms/repositories/category_repository.dart';
import 'package:wms/services/category_api_service.dart';

/// Презентер для управления категориями.
class CategoryPresenter {
  final CategoryRepository _categoryRepository;

  CategoryPresenter({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ??
            CategoryRepository(
              categoryAPIService:
                  CategoryAPIService(baseUrl: AppConstants.apiBaseUrl),
            );

  /// Получает список всех категорий.
  Future<List<wms_category.Category>> fetchAllCategory() async {
    return await _categoryRepository.getAllCategory();
  }

  /// Получает категорию по её ID.
  Future<wms_category.Category> fetchCategoryById(int categoryId) async {
    return await _categoryRepository.getCategoryById(categoryId);
  }

  /// Создает новую категорию.
  Future<void> createCategory({required String categoryName}) async {
    final category = wms_category.Category(
      categoryID: 0,
      categoryName: categoryName,
    );
    await _categoryRepository.createCategory(category);
  }

  /// Обновляет данные категории.
  Future<void> updateCategory(
    wms_category.Category category, {
    String? name,
  }) async {
    if (name != null) {
      category.categoryName = name;
    }
    await _categoryRepository.updateCategory(category);
  }

  /// Удаляет категорию.
  Future<void> deleteCategory(wms_category.Category category) async {
    await _categoryRepository.deleteCategory(category.categoryID);
  }
}
