import 'package:wms/models/receive.dart';
import 'package:wms/models/product.dart';
import 'package:wms/services/receive_api_service.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/services/category_api_service.dart';
import 'package:wms/services/cell_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с приёмками через ReceiveAPIService, ProductAPIService,
/// CategoryAPIService и CellAPIService.
class ReceiveRepository {
  final ReceiveAPIService receiveAPIService;
  final ProductAPIService productAPIService;
  final CategoryAPIService categoryAPIService;
  final CellAPIService cellAPIService;
  final SessionManager _sessionManager;

  ReceiveRepository({
    ReceiveAPIService? receiveAPIService,
    ProductAPIService? productAPIService,
    CategoryAPIService? categoryAPIService,
    CellAPIService? cellAPIService,
    required String baseUrl,
  })  : receiveAPIService =
      receiveAPIService ?? ReceiveAPIService(baseUrl: baseUrl),
        productAPIService =
            productAPIService ?? ProductAPIService(baseUrl: baseUrl),
        categoryAPIService =
            categoryAPIService ?? CategoryAPIService(baseUrl: baseUrl),
        cellAPIService = cellAPIService ?? CellAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех записей приёмки.
  Future<List<Receive>> getAllReceives() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> receiveMaps =
    await receiveAPIService.getAllReceives();
    List<Receive> receives = [];
    for (var map in receiveMaps) {
      int productId = map['ProductID'] ?? 0;
      int cellId = map['CellID'] ?? 0;
      final productMap = await productAPIService.getProductById(productId);
      int categoryId = productMap['CategoryID'] ?? 0;
      final category = await categoryAPIService.getCategoryById(categoryId);
      Product product = Product.fromJson(productMap, category);
      final cell = await cellAPIService.getCellById(cellId);
      receives.add(Receive.fromJson(map, product: product, cell: cell));
    }
    return receives;
  }

  /// Получает запись приёмки по её ID.
  Future<Receive> getReceiveById(int receiveId) async {
    await _sessionManager.validateSession();
    final Map<String, dynamic> receiveMap =
    await receiveAPIService.getReceiveById(receiveId);
    int productId = receiveMap['ProductID'] ?? 0;
    int cellId = receiveMap['CellID'] ?? 0;
    final productMap = await productAPIService.getProductById(productId);
    int categoryId = productMap['CategoryID'] ?? 0;
    final category = await categoryAPIService.getCategoryById(categoryId);
    Product product = Product.fromJson(productMap, category);
    final cell = await cellAPIService.getCellById(cellId);
    return Receive.fromJson(receiveMap, product: product, cell: cell);
  }

  /// Создает новую запись приёмки.
  Future<String> createReceive(Receive receive) async {
    await _sessionManager.validateSession();
    return await receiveAPIService.createReceive(receive.toJson());
  }

  /// Обновляет запись приёмки.
  Future<String> updateReceive(Receive receive) async {
    await _sessionManager.validateSession();
    return await receiveAPIService.updateReceive(receive.toJson(), receive.receiveID);
  }

  /// Удаляет запись приёмки по её ID.
  Future<String> deleteReceive(int receiveId) async {
    await _sessionManager.validateSession();
    return await receiveAPIService.deleteReceive(receiveId);
  }
}
