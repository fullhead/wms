import 'package:wms/core/constants.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/repositories/receive_repository.dart';
import 'package:wms/services/receive_api_service.dart';

/// Презентер для управления приёмками.
class ReceivePresenter {
  final ReceiveRepository _repo =
  ReceiveRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Доступ к API (нужно, например, для отчётов).
  ReceiveAPIService get receiveApiService => _repo.receiveAPIService;

  /// Получает список всех приёмок с продуктами и ячейками.
  Future<List<Receive>> fetchAllReceives() => _repo.getAllReceives();
  Future<Receive> getReceiveById(int id) => _repo.getReceiveById(id);

  /// Создание новой записи приёмки.
  Future<String> createReceive({
    required Product product,
    required Cell cell,
    required int receiveQuantity,
    DateTime? receiveDate,
  }) {
    final receive = Receive(
      receiveID: 0,
      product: product,
      cell: cell,
      receiveQuantity: receiveQuantity,
      receiveDate: receiveDate ?? DateTime.now(),
    );
    return _repo.createReceive(receive);
  }

  /// Обновление записи приёмки.
  Future<String> updateReceive(
      Receive receive, {
        Product? product,
        Cell? cell,
        int? receiveQuantity,
        DateTime? receiveDate,
      }) {
    if (product != null) receive.product = product;
    if (cell != null) receive.cell = cell;
    if (receiveQuantity != null) receive.receiveQuantity = receiveQuantity;
    if (receiveDate != null) receive.receiveDate = receiveDate;
    return _repo.updateReceive(receive);
  }

  /// Удаление записи приёмки.
  Future<String> deleteReceive(Receive receive) =>
      _repo.deleteReceive(receive.receiveID);
}
