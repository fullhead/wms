import 'package:wms/models/warehouse.dart';
import 'package:wms/services/warehouse_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы со складом.
class WarehouseRepository {
  final WarehouseAPIService warehouseAPIService;
  final SessionManager _sessionManager;

  WarehouseRepository({
    WarehouseAPIService? warehouseAPIService,
    required String baseUrl,
  })  : warehouseAPIService =
      warehouseAPIService ?? WarehouseAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех записей склада.
  Future<List<Warehouse>> getAllWarehouse() async {
    await _sessionManager.validateSession();
    final maps = await warehouseAPIService.getAllWarehouse();
    return maps.map((m) => Warehouse.fromJsonWithDetails(m)).toList();
  }

  /// Получает запись склада по её ID.
  Future<Warehouse> getWarehouseById(int id) async {
    await _sessionManager.validateSession();
    final map = await warehouseAPIService.getWarehouseById(id);
    return Warehouse.fromJsonWithDetails(map);
  }
}
