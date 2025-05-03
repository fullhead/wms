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

  /// Получает список всех записей склада (уже с деталями).
  Future<List<Map<String, dynamic>>> getAllWarehouse() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse?withDetails=true');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['error'] ?? 'Неизвестная ошибка при получении склада');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает конкретную запись склада по ID (с деталями).
  Future<Map<String, dynamic>> getWarehouseById(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/warehouse/$id?withDetails=true');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['error'] ?? 'Неизвестная ошибка при получении склада по ID');
      }
    } catch (e) {
      rethrow;
    }
  }
}
