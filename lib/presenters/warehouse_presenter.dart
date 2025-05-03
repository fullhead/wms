import 'package:wms/core/constants.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/repositories/warehouse_repository.dart';
import 'package:wms/services/warehouse_api_service.dart';

/// Презентер для управления данными склада.
class WarehousePresenter {
  final WarehouseRepository _repo =
  WarehouseRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Доступ к WarehouseAPIService
  WarehouseAPIService get warehouseApiService => _repo.warehouseAPIService;

  /// Список всех складских позиций.
  Future<List<Warehouse>> fetchAllWarehouse() => _repo.getAllWarehouse();

  /// Запись склада по ID.
  Future<Warehouse> fetchWarehouseById(int id) => _repo.getWarehouseById(id);
}
