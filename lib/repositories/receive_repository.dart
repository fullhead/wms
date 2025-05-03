import 'package:wms/models/receive.dart';
import 'package:wms/services/receive_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с приёмками.
class ReceiveRepository {
  final ReceiveAPIService receiveAPIService;
  final SessionManager _sessionManager = SessionManager();

  ReceiveRepository({required String baseUrl})
      : receiveAPIService = ReceiveAPIService(baseUrl: baseUrl);

  /// Получает список всех записей приёмки (+ детали).
  Future<List<Receive>> getAllReceives() async {
    await _sessionManager.validateSession();
    final maps = await receiveAPIService.getAllReceives();
    return maps.map(Receive.fromJsonWithDetails).toList();
  }

  /// Получает запись приёмки по её ID (+ детали).
  Future<Receive> getReceiveById(int id) async {
    await _sessionManager.validateSession();
    final map = await receiveAPIService.getReceiveById(id);
    return Receive.fromJsonWithDetails(map);
  }

  /// Создаёт новую запись приёмки.
  Future<String> createReceive(Receive r) async {
    await _sessionManager.validateSession();
    return receiveAPIService.createReceive(r.toJson());
  }

  /// Обновляет запись приёмки.
  Future<String> updateReceive(Receive r) async {
    await _sessionManager.validateSession();
    return receiveAPIService.updateReceive(r.toJson(), r.receiveID);
  }

  /// Удаляет запись приёмки.
  Future<String> deleteReceive(int id) async {
    await _sessionManager.validateSession();
    return receiveAPIService.deleteReceive(id);
  }
}
