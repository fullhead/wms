import 'package:wms/models/product.dart';
import 'package:wms/models/category.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с продукцией через ProductAPIService и CategoryAPIService.
class ProductRepository {
  final ProductAPIService productAPIService;
  final CategoryAPIService categoryAPIService;
  final SessionManager _sessionManager;

  ProductRepository({
    ProductAPIService? productAPIService,
    CategoryAPIService? categoryAPIService,
    required String baseUrl,
  })  : productAPIService = productAPIService ?? ProductAPIService(baseUrl: baseUrl),
        categoryAPIService = categoryAPIService ?? CategoryAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всей продукции.
  Future<List<Product>> getAllProducts() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> productMaps = await productAPIService.getAllProduct();
    List<Product> products = [];
    for (var map in productMaps) {
      int categoryId = map['CategoryID'] ?? 0;
      Category category = await categoryAPIService.getCategoryById(categoryId);
      products.add(Product.fromJson(map, category));
    }
    return products;
  }

  /// Получает продукт по его ID.
  Future<Product> getProductById(int productId) async {
    await _sessionManager.validateSession();
    final Map<String, dynamic> productMap = await productAPIService.getProductById(productId);
    int categoryId = productMap['CategoryID'] ?? 0;
    Category category = await categoryAPIService.getCategoryById(categoryId);
    return Product.fromJson(productMap, category);
  }

  /// Создает новую продукцию.
  Future<String> createProduct(Product product) async {
    await _sessionManager.validateSession();
    return await productAPIService.createProduct(product.toJson());
  }

  /// Обновляет данные продукции.
  Future<String> updateProduct(Product product) async {
    await _sessionManager.validateSession();
    return await productAPIService.updateProduct(product.toJson(), product.productID);
  }

  /// Удаляет продукцию по её ID.
  Future<String> deleteProduct(int productID) async {
    await _sessionManager.validateSession();
    return await productAPIService.deleteProduct(productID);
  }
}
