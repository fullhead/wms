import 'package:wms/models/product.dart';
import 'package:wms/models/category.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';

/// Репозиторий для работы с продукцией через ProductAPIService и CategoryAPIService.
class ProductRepository {
  final ProductAPIService productAPIService;
  final CategoryAPIService categoryAPIService;

  ProductRepository({
    ProductAPIService? productAPIService,
    CategoryAPIService? categoryAPIService, required String baseUrl
  })  : productAPIService = productAPIService ??
            ProductAPIService(baseUrl: baseUrl),
        categoryAPIService = categoryAPIService ??
            CategoryAPIService(baseUrl: baseUrl);

  /// Получает список всей продукции.
  Future<List<Product>> getAllProducts() async {
    final List<Map<String, dynamic>> productMaps =
        await productAPIService.getAllProduct();
    List<Product> products = [];
    // Для каждого продукта получаем данные категории через CategoryAPIService
    for (var map in productMaps) {
      int categoryId = map['CategoryID'] ?? 0;
      Category category = await categoryAPIService.getCategoryById(categoryId);
      products.add(Product.fromJson(map, category));
    }
    return products;
  }

  /// Получает продукт по его ID.
  Future<Product> getProductById(int productId) async {
    final Map<String, dynamic> productMap =
        await productAPIService.getProductById(productId);
    int categoryId = productMap['CategoryID'] ?? 0;
    Category category = await categoryAPIService.getCategoryById(categoryId);
    return Product.fromJson(productMap, category);
  }

  /// Создает новую продукцию.
  Future<String> createProduct(Product product) async {
    return await productAPIService.createProduct(product.toJson());
  }

  /// Обновляет данные продукции.
  Future<String> updateProduct(Product product) async {
    return await productAPIService.updateProduct(
        product.toJson(), product.productID);
  }

  /// Удаляет продукцию по ее ID.
  Future<String> deleteProduct(int productID) async {
    return await productAPIService.deleteProduct(productID);
  }
}
