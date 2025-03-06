import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы со складом через REST API.
class WarehouseAPIService {
  final String baseUrl;

  WarehouseAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов, добавляя токен авторизации при необходимости.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает список всех записей склада.
  Future<List<Map<String, dynamic>>> getAllWarehouse() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/warehouse'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.getAllWarehouse: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.getAllWarehouse error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при получении данных склада');
    }
  }

  /// Получает данные склада по его ID.
  Future<Map<String, dynamic>> getWarehouseById(int warehouseId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/warehouse/$warehouseId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('WarehouseAPIService.getWarehouseById ($warehouseId): ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.getWarehouseById error ($warehouseId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при получении записи склада');
    }
  }

  /// Создает новую запись склада.
  Future<String> createWarehouse(Map<String, dynamic> warehouseMap) async {
    final headers = await _getHeaders();
    debugPrint('WarehouseAPIService.createWarehouse payload: ${jsonEncode(warehouseMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/warehouse'),
      headers: headers,
      body: jsonEncode(warehouseMap),
    );
    if (response.statusCode == 201) {
      debugPrint('WarehouseAPIService.createWarehouse: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Запись склада создана';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.createWarehouse error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при создании записи склада');
    }
  }

  /// Обновляет данные склада.
  Future<String> updateWarehouse(Map<String, dynamic> warehouseMap, int warehouseId) async {
    final headers = await _getHeaders();
    debugPrint('WarehouseAPIService.updateWarehouse payload for warehouseId $warehouseId: ${jsonEncode(warehouseMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/warehouse/$warehouseId'),
      headers: headers,
      body: jsonEncode(warehouseMap),
    );
    if (response.statusCode == 200) {
      debugPrint('WarehouseAPIService.updateWarehouse ($warehouseId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Запись склада обновлена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.updateWarehouse error ($warehouseId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при обновлении записи склада');
    }
  }

  /// Удаляет запись склада по его ID.
  Future<String> deleteWarehouse(int warehouseId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/warehouse/$warehouseId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('WarehouseAPIService.deleteWarehouse ($warehouseId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Запись склада удалена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('WarehouseAPIService.deleteWarehouse error ($warehouseId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при удалении записи склада');
    }
  }
}
