import 'package:wms/models/product.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с продукцией через ProductAPIService и CategoryAPIService.
class ProductRepository {
  final ProductAPIService productAPIService;
  final CategoryAPIService categoryAPIService;
  final SessionManager _sessionManager = SessionManager();

  ProductRepository({required String baseUrl})
      : productAPIService = ProductAPIService(baseUrl: baseUrl),
        categoryAPIService = CategoryAPIService(baseUrl: baseUrl);

  /// Получает список всей продукции вместе с названием категорий.
  Future<List<Product>> getAllProducts() async {
    await _sessionManager.validateSession();
    final maps = await productAPIService.getAllProduct();
    return maps.map(Product.fromJsonWithCategory).toList();
  }

  /// Получает продукт по его ID.
  Future<Product> getProductById(int id) async {
    await _sessionManager.validateSession();
    final map = await productAPIService.getProductById(id);
    return Product.fromJsonWithCategory(map);
  }

  /// Создает новую продукцию.
  Future<String> createProduct(Product p) async {
    await _sessionManager.validateSession();
    return productAPIService.createProduct(p.toJson());
  }

  /// Обновляет данные продукции.
  Future<String> updateProduct(Product p) async {
    await _sessionManager.validateSession();
    return productAPIService.updateProduct(p.toJson(), p.productID);
  }

  /// Удаляет продукцию по её ID.
  Future<String> deleteProduct(int id) async {
    await _sessionManager.validateSession();
    return productAPIService.deleteProduct(id);
  }
}
