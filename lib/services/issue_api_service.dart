import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с выдачей через REST API.
class IssueAPIService {
  final String baseUrl;

  IssueAPIService({required this.baseUrl});

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

  /// Список всех выдач. По умолчанию сразу тянем детали.
  Future<List<Map<String, dynamic>>> getAllIssue({bool withDetails = true}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues${withDetails ? '?withDetails=true' : ''}');
    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    final err = jsonDecode(resp.body);
    throw ApiException(err['error'] ?? 'Ошибка получения выдач');
  }

  /// Одна запись по ID.
  Future<Map<String, dynamic>> getIssueById(int id, {bool withDetails = true}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$id${withDetails ? '?withDetails=true' : ''}');
    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(resp.body);
    throw ApiException(err['error'] ?? 'Ошибка получения выдачи');
  }

  /// Создает новую запись выдачи.
  Future<String> createIssue(Map<String, dynamic> issueMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues');
    try {
      final response =
      await http.post(uri, headers: headers, body: jsonEncode(issueMap));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при создании записи выдачи');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет запись выдачи.
  Future<String> updateIssue(Map<String, dynamic> issueMap, int issueId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$issueId');
    try {
      final response =
      await http.put(uri, headers: headers, body: jsonEncode(issueMap));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении записи выдачи');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет запись выдачи.
  Future<String> deleteIssue(int issueId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/issues/$issueId');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Запись выдачи удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении записи выдачи');
      }
    } catch (e) {
      rethrow;
    }
  }
}
