import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/cell.dart';

/// Сервис для работы с ячейками через REST API.
class CellAPIService {
  final String baseUrl;

  CellAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если auth равен true, то добавляется access token авторизации.
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

  /// Получает список всех ячеек.
  Future<List<Map<String, dynamic>>> getAllCells() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('CellAPIService.getAllCells error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячеек');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает ячейку по её ID.
  Future<Cell> getCellById(int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Cell.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('CellAPIService.getCellById error ($cellId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячейки по ID');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создает новую ячейку.
  Future<String> createCell(Map<String, dynamic> cellMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(cellMap)}');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(cellMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка создана';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('CellAPIService.createCell error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании ячейки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет данные ячейки по её ID.
  Future<String> updateCell(Map<String, dynamic> cellMap, int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(cellMap)}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(cellMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('CellAPIService.updateCell error ($cellId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении ячейки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет ячейку по её ID.
  Future<String> deleteCell(int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка удалена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('CellAPIService.deleteCell error ($cellId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении ячейки');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
