import 'package:wms/core/constants.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/category.dart';
import 'package:wms/repositories/product_repository.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';

/// Презентер для управления продукцией.
class ProductPresenter {
  final ProductRepository _repo =
  ProductRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Геттер для доступа к ProductAPIService.
  ProductAPIService get productApiService => _repo.productAPIService;

  /// Геттер для доступа к CategoryAPIService.
  CategoryAPIService get categoryApiService => _repo.categoryAPIService;

  /// Получает список всех продуктов с категориями.
  Future<List<Product>> fetchAllProduct() => _repo.getAllProducts();

  /// Получает список всех продуктов без категорий.
  Future<Product> getProductById(int id) => _repo.getProductById(id);

  /// Создает новую продукцию.
  Future<String> createProduct({
    required Category category,
    required String productName,
    required String productBarcode,
    String productImage = '',
  }) =>
      _repo.createProduct(
        Product(
          productID: 0,
          productCategory: category,
          productName: productName,
          productImage: productImage,
          productBarcode: productBarcode,
        ),
      );

  /// Обновляет данные продукции.
  Future<String> updateProduct(
      Product product, {
        Category? category,
        String? productName,
        String? productImage,
        String? productBarcode,
      }) {
    if (category != null) product.productCategory = category;
    if (productName != null) product.productName = productName;
    if (productImage != null) product.productImage = productImage;
    if (productBarcode != null) product.productBarcode = productBarcode;
    return _repo.updateProduct(product);
  }

  /// Удаляет продукцию.
  Future<String> deleteProduct(Product p) => _repo.deleteProduct(p.productID);
}