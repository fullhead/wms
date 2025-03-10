import 'package:wms/models/cell.dart';
import 'package:wms/services/cell_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с ячейками через CellAPIService.
class CellRepository {
  final CellAPIService cellAPIService;
  final SessionManager _sessionManager;

  CellRepository({CellAPIService? cellAPIService, required String baseUrl})
      : cellAPIService = cellAPIService ?? CellAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает список всех ячеек.
  Future<List<Cell>> getAllCells() async {
    await _sessionManager.validateSession();
    final List<Map<String, dynamic>> cellMaps = await cellAPIService.getAllCells();
    return cellMaps.map((map) => Cell.fromJson(map)).toList();
  }

  /// Получает ячейку по её ID.
  Future<Cell> getCellById(int cellId) async {
    await _sessionManager.validateSession();
    return await cellAPIService.getCellById(cellId);
  }

  /// Создает новую ячейку.
  Future<String> createCell(Cell cell) async {
    await _sessionManager.validateSession();
    return await cellAPIService.createCell(cell.toJson());
  }

  /// Обновляет данные ячейки.
  Future<String> updateCell(Cell cell) async {
    await _sessionManager.validateSession();
    return await cellAPIService.updateCell(cell.toJson(), cell.cellID);
  }

  /// Удаляет ячейку по её ID.
  Future<String> deleteCell(int cellId) async {
    await _sessionManager.validateSession();
    return await cellAPIService.deleteCell(cellId);
  }
}
