import 'package:wms/models/cell.dart';
import 'package:wms/services/cell_api_service.dart';

/// Репозиторий для работы с ячейками через CellAPIService.
class CellRepository {
  final CellAPIService cellAPIService;

  CellRepository({CellAPIService? cellAPIService, required String baseUrl})
      : cellAPIService = cellAPIService ?? CellAPIService(baseUrl: baseUrl);

  /// Получает список всех ячеек.
  Future<List<Cell>> getAllCells() async {
    final List<Map<String, dynamic>> cellMaps = await cellAPIService.getAllCells();
    return cellMaps.map((map) => Cell.fromJson(map)).toList();
  }

  /// Получает ячейку по её ID.
  Future<Cell> getCellById(int cellId) async {
    return await cellAPIService.getCellById(cellId);
  }

  /// Создает новую ячейку.
  Future<String> createCell(Cell cell) async {
    return await cellAPIService.createCell(cell.toJson());
  }

  /// Обновляет данные ячейки.
  Future<String> updateCell(Cell cell) async {
    return await cellAPIService.updateCell(cell.toJson(), cell.cellID);
  }

  /// Удаляет ячейку по её ID.
  Future<String> deleteCell(int cellId) async {
    return await cellAPIService.deleteCell(cellId);
  }
}
