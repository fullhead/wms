import 'package:wms/models/warehouse.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';
import 'package:wms/services/warehouse_api_service.dart';
import 'package:wms/services/cell_api_service.dart';
import 'package:wms/services/product_api_service.dart';
import 'package:wms/models/category.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы со складом через WarehouseAPIService, CellAPIService и ProductAPIService.
class WarehouseRepository {
  final WarehouseAPIService warehouseAPIService;
  final CellAPIService cellAPIService;
  final ProductAPIService productAPIService;
  final SessionManager _sessionManager;

  WarehouseRepository({
    WarehouseAPIService? warehouseAPIService,
    CellAPIService? cellAPIService,
    ProductAPIService? productAPIService,
    required String baseUrl,
  })  : warehouseAPIService = warehouseAPIService ?? WarehouseAPIService(baseUrl: baseUrl),
        cellAPIService = cellAPIService ?? CellAPIService(baseUrl: baseUrl),
        productAPIService = productAPIService ?? ProductAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех записей склада.
  Future<List<Warehouse>> getAllWarehouse() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> warehouseMaps = await warehouseAPIService.getAllWarehouse();
    final List<Future<Warehouse>> futures = warehouseMaps.map((map) async {
      final int cellId = map['CellID'];
      final int productId = map['ProductID'];
      final cellFuture = cellAPIService.getCellById(cellId);
      final productFuture = productAPIService.getProductById(productId);
      final results = await Future.wait([cellFuture, productFuture]);
      final Cell cell = results[0] as Cell;
      final Map<String, dynamic> productMap = results[1] as Map<String, dynamic>;
      final Product product = Product.fromJson(productMap, Category(categoryID: 0, categoryName: ''));
      return Warehouse.fromJson(map, cell, product);
    }).toList();
    return await Future.wait(futures);
  }

  /// Получает запись склада по его ID.
  Future<Warehouse> getWarehouseById(int warehouseId) async {
    await _sessionManager.validateSession();
    final Map<String, dynamic> map = await warehouseAPIService.getWarehouseById(warehouseId);
    final int cellId = map['CellID'];
    final int productId = map['ProductID'];
    final cellAPIServiceFuture = cellAPIService.getCellById(cellId);
    final productAPIServiceFuture = productAPIService.getProductById(productId);
    final results = await Future.wait([cellAPIServiceFuture, productAPIServiceFuture]);
    final Cell cell = results[0] as Cell;
    final Map<String, dynamic> productMap = results[1] as Map<String, dynamic>;
    final Product product = Product.fromJson(productMap, Category(categoryID: 0, categoryName: ''));
    return Warehouse.fromJson(map, cell, product);
  }
}
