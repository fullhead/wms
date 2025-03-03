import 'package:wms/core/constants.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/category.dart';
import 'package:wms/repositories/product_repository.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';

/// Презентер для управления продукцией.
class ProductPresenter {
  final ProductRepository _productRepository;

  ProductPresenter({ProductRepository? productRepository})
      : _productRepository = productRepository ??
            ProductRepository(productAPIService:
                  ProductAPIService(baseUrl: AppConstants.apiBaseUrl),
              categoryAPIService:
                  CategoryAPIService(baseUrl: AppConstants.apiBaseUrl),
            );

  /// Геттер для доступа к ProductAPIService.
  ProductAPIService get productApiService => _productRepository.productAPIService;

  /// Геттер для доступа к CategoryAPIService.
  CategoryAPIService get categoryApiService => _productRepository.categoryAPIService;

  /// Получает список всей продукции.
  Future<List<Product>> fetchAllProduct() async {
    return await _productRepository.getAllProducts();
  }

  /// Получает продукцию по её ID.
  Future<Product> fetchProductById(int productId) async {
    return await _productRepository.getProductById(productId);
  }

  /// Создает новую продукцию.
  Future<String> createProduct({
    required Category category,
    required String productName,
    String productImage = '',
    required String productBarcode,
  }) async {
    final product = Product(
      productID: 0,
      productCategory: category,
      productName: productName,
      productImage: productImage,
      productBarcode: productBarcode,
    );
    return await _productRepository.createProduct(product);
  }

  /// Обновляет данные продукции.
  Future<String> updateProduct(
    Product product, {
    Category? category,
    String? productName,
    String? productImage,
    String? productBarcode,
  }) async {
    if (category != null) product.productCategory = category;
    if (productName != null) product.productName = productName;
    if (productImage != null) product.productImage = productImage;
    if (productBarcode != null) product.productBarcode = productBarcode;
    return await _productRepository.updateProduct(product);
  }

  /// Удаляет продукцию.
  Future<String> deleteProduct(Product product) async {
    return await _productRepository.deleteProduct(product.productID);
  }
}
