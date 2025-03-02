import 'package:wms/core/constants.dart';
import 'package:wms/models/category.dart';
import 'package:wms/repositories/category_repository.dart';
import 'package:wms/services/api_service.dart';

/// Презентер для управления категориями.
class CategoryPresenter {
  final CategoryRepository _categoryRepository;

  CategoryPresenter({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ??
      CategoryRepository(
          apiService: APIService(baseUrl: AppConstants.apiBaseUrl));

  /// Получает список всех категорий.
  Future<List<Category>> fetchAllCategory() async {
    return await _categoryRepository.getAllCategory();
  }

  /// Получает категорию по её ID.
  Future<Category> fetchCategoryById(int categoryId) async {
    return await _categoryRepository.getCategoryById(categoryId);
  }

  /// Создает новую категорию.
  Future<void> createCategory({required String categoryName}) async {
    final category = Category(
      categoryID: 0,
      categoryName: categoryName,
    );
    await _categoryRepository.createCategory(category);
  }

  /// Обновляет данные категории.
  Future<void> updateCategory(
      Category category, {
        String? name,
      }) async {
    if (name != null) {
      category.categoryName = name;
    }
    await _categoryRepository.updateCategory(category);
  }

  /// Удаляет категорию.
  Future<void> deleteCategory(Category category) async {
    await _categoryRepository.deleteCategory(category.categoryID);
  }
}
