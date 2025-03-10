import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы со складом через REST API.
class WarehouseAPIService {
  final String baseUrl;

  WarehouseAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов, добавляя access token авторизации при необходимости.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает список всех записей склада.
  Future<List<Map<String, dynamic>>> getAllWarehouse() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.getAllWarehouse: ${response.body}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.getAllWarehouse error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при получении данных склада');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает данные склада по его ID.
  Future<Map<String, dynamic>> getWarehouseById(int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('WarehouseAPIService.getWarehouseById ($warehouseId): ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.getWarehouseById error ($warehouseId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при получении записи склада');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создает новую запись склада.
  Future<String> createWarehouse(Map<String, dynamic> warehouseMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(warehouseMap)}');

    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(warehouseMap));
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        debugPrint('WarehouseAPIService.createWarehouse: ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада создана';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.createWarehouse error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при создании записи склада');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет данные склада.
  Future<String> updateWarehouse(Map<String, dynamic> warehouseMap, int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(warehouseMap)}');

    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(warehouseMap));
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('WarehouseAPIService.updateWarehouse ($warehouseId): ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.updateWarehouse error ($warehouseId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении записи склада');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет запись склада по его ID.
  Future<String> deleteWarehouse(int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('WarehouseAPIService.deleteWarehouse ($warehouseId): ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада удалена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('WarehouseAPIService.deleteWarehouse error ($warehouseId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении записи склада');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
