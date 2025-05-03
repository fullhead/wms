import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с приёмками через REST API.
class ReceiveAPIService {
  final String baseUrl;

  ReceiveAPIService({required this.baseUrl});

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

  /// Получает список всех записей приёмки (+ детали).
  Future<List<Map<String, dynamic>>> getAllReceives() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives?withDetails=true');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw ApiException((jsonDecode(res.body))['error'] ?? 'Неизвестная ошибка при получении данных приёмки');
  }

  /// Получает запись приёмки по её ID (+ детали).
  Future<Map<String, dynamic>> getReceiveById(int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId?withDetails=true');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException((jsonDecode(res.body))['error'] ?? 'Неизвестная ошибка при получении записи приёмки по ID');
  }

  /// Создает новую запись приёмки.
  Future<String> createReceive(Map<String, dynamic> receiveMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives');
    try {
      final response =
      await http.post(uri, headers: headers, body: jsonEncode(receiveMap));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании записи приёмки');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет запись приёмки.
  Future<String> updateReceive(Map<String, dynamic> receiveMap, int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId');
    try {
      final response =
      await http.put(uri, headers: headers, body: jsonEncode(receiveMap));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении записи приёмки');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет запись приёмки.
  Future<String> deleteReceive(int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении записи приёмки');
      }
    } catch (e) {
      rethrow;
    }
  }
}
