import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы со складом через REST API.
class WarehouseAPIService {
  final String baseUrl;

  WarehouseAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, добавляется access token авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает список всех записей склада.
  Future<List<Map<String, dynamic>>> getAllWarehouse() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении данных склада');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает данные склада по его ID.
  Future<Map<String, dynamic>> getWarehouseById(int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении записи склада');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создает новую запись склада.
  Future<String> createWarehouse(Map<String, dynamic> warehouseMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse');
    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(warehouseMap));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при создании записи склада');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные склада.
  Future<String> updateWarehouse(Map<String, dynamic> warehouseMap, int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(warehouseMap));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении записи склада');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет запись склада по его ID.
  Future<String> deleteWarehouse(int warehouseId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$warehouseId');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись склада удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении записи склада');
      }
    } catch (e) {
      rethrow;
    }
  }
}
