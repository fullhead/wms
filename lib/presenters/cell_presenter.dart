import 'package:wms/core/constants.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/repositories/cell_repository.dart';

/// Презентер для управления ячейками.
class CellPresenter {
  final CellRepository _cellRepository;

  CellPresenter({CellRepository? cellRepository})
      : _cellRepository = cellRepository ?? CellRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Получает список всех ячеек.
  Future<List<Cell>> fetchAllCells() async {
    return await _cellRepository.getAllCells();
  }

  /// Создает новую ячейку.
  Future<String> createCell({required String cellName}) async {
    final cell = Cell(
      cellID: 0,
      cellName: cellName,
    );
    return await _cellRepository.createCell(cell);
  }

  /// Обновляет данные ячейки.
  Future<String> updateCell(Cell cell, {String? name}) async {
    if (name != null) {
      cell.cellName = name;
    }
    return await _cellRepository.updateCell(cell);
  }

  /// Удаляет ячейку.
  Future<String> deleteCell(Cell cell) async {
    return await _cellRepository.deleteCell(cell.cellID);
  }
}
