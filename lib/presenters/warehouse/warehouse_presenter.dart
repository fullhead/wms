import 'package:wms/core/constants.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/repositories/warehouse_repository.dart';
import 'package:wms/services/warehouse_api_service.dart';

/// Презентер для управления складом.
class WarehousePresenter {
  final WarehouseRepository _warehouseRepository;

  WarehousePresenter({WarehouseRepository? warehouseRepository})
      : _warehouseRepository =
      warehouseRepository ?? WarehouseRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Геттер для доступа к WarehouseAPIService.
  WarehouseAPIService get warehouseApiService => _warehouseRepository.warehouseAPIService;

  /// Получает список всех записей склада.
  Future<List<Warehouse>> fetchAllWarehouse() {
    return _warehouseRepository.getAllWarehouse();
  }

  /// Получает запись склада по его ID.
  Future<Warehouse> fetchWarehouseById(int warehouseId) {
    return _warehouseRepository.getWarehouseById(warehouseId);
  }
}
