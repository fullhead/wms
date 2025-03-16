import 'package:wms/core/constants.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/repositories/receive_repository.dart';
import 'package:wms/services/receive_api_service.dart';
import 'package:wms/services/product_api_service.dart';

/// Презентер для управления приёмками.
class ReceivePresenter {
  final ReceiveRepository _receiveRepository;

  ReceivePresenter({ReceiveRepository? receiveRepository})
      : _receiveRepository = receiveRepository ?? ReceiveRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Геттер для доступа к ReceiveAPIService.
  ReceiveAPIService get receiveApiService => _receiveRepository.receiveAPIService;

  /// Геттер для доступа к ProductAPIService.
  ProductAPIService get productApiService => _receiveRepository.productAPIService;

  /// Получает список всех записей приёмки.
  Future<List<Receive>> fetchAllReceives() async {
    return _receiveRepository.getAllReceives();
  }

  /// Создает новую запись приёмки.
  Future<String> createReceive({required Product product, required Cell cell, required int receiveQuantity, DateTime? receiveDate}) async {
    final receive = Receive(
      receiveID: 0,
      product: product,
      cell: cell,
      receiveQuantity: receiveQuantity,
      receiveDate: receiveDate ?? DateTime.now(),
    );
    return _receiveRepository.createReceive(receive);
  }

  /// Обновляет данные записи приёмки.
  Future<String> updateReceive(Receive receive, {Product? product, Cell? cell, int? receiveQuantity, DateTime? receiveDate}) async {
    if (product != null) {
      receive.product = product;
    }
    if (cell != null) {
      receive.cell = cell;
    }
    if (receiveQuantity != null) {
      receive.receiveQuantity = receiveQuantity;
    }
    if (receiveDate != null) {
      receive.receiveDate = receiveDate;
    }
    return _receiveRepository.updateReceive(receive);
  }

  /// Удаляет запись приёмки.
  Future<String> deleteReceive(Receive receive) async {
    return _receiveRepository.deleteReceive(receive.receiveID);
  }
}
