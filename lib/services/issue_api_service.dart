import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с выдачей через REST API.
class IssueAPIService {
  final String baseUrl;

  IssueAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов. Если [auth] == true, добавляет access token авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Получает список всех записей выдачи.
  Future<List<Map<String, dynamic>>> getAllIssues() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues');
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
        debugPrint('IssueAPIService.getAllIssues error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при получении данных выдачи');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает запись выдачи по её ID.
  Future<Map<String, dynamic>> getIssueById(int issueId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$issueId');
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
        debugPrint('IssueAPIService.getIssueById error ($issueId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при получении записи выдачи по ID');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создает новую запись выдачи.
  Future<String> createIssue(Map<String, dynamic> issueMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(issueMap)}');

    try {
      final response =
      await http.post(uri, headers: headers, body: jsonEncode(issueMap));
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи создана';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('IssueAPIService.createIssue error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при создании записи выдачи');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет запись выдачи.
  Future<String> updateIssue(Map<String, dynamic> issueMap, int issueId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$issueId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(issueMap)}');

    try {
      final response =
      await http.put(uri, headers: headers, body: jsonEncode(issueMap));
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('IssueAPIService.updateIssue error ($issueId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении записи выдачи');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет запись выдачи.
  Future<String> deleteIssue(int issueId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$issueId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи удалена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('IssueAPIService.deleteIssue error ($issueId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении записи выдачи');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
