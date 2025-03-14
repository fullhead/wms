import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с приёмками через REST API.
class ReceiveAPIService {
  final String baseUrl;

  ReceiveAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов. Если [auth] == true, добавляет access token авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Получает список всех записей приёмки.
  Future<List<Map<String, dynamic>>> getAllReceives() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives');
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
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint(
            'ReceiveAPIService.getAllReceives error: ${response.body}');
        throw ApiException(errorData['error'] ??
            'Неизвестная ошибка при получении данных приёмки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает запись приёмки по её ID.
  Future<Map<String, dynamic>> getReceiveById(int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('ReceiveAPIService.getReceiveById error ($receiveId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении записи приёмки по ID');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создает новую запись приёмки.
  Future<String> createReceive(Map<String, dynamic> receiveMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(receiveMap)}');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(receiveMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки создана';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('ReceiveAPIService.createReceive error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании записи приёмки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет запись приёмки.
  Future<String> updateReceive(Map<String, dynamic> receiveMap, int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(receiveMap)}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(receiveMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('ReceiveAPIService.updateReceive error ($receiveId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении записи приёмки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет запись приёмки.
  Future<String> deleteReceive(int receiveId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/receives/$receiveId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись приёмки удалена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('ReceiveAPIService.deleteReceive error ($receiveId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении записи приёмки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
