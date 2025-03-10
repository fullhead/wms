import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/session/session_manager.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/category.dart' as wms_category;

/// Сервис для работы с категориями через REST API.
class CategoryAPIService {
  final String baseUrl;

  CategoryAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если auth равен true, то производится проверка сессии и добавляется access token.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      // Проверяем сессию перед получением токена
      final sessionManager = SessionManager();
      await sessionManager.validateSession();
      final token = await AuthStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает список всех категорий.
  Future<List<Map<String, dynamic>>> getAllCategory() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories');
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
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категорий');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает категорию по её ID.
  Future<wms_category.Category> getCategoryById(int categoryId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryId');
    final startTime = DateTime.now();

    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return wms_category.Category.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категории по ID');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создает новую категорию.
  Future<String> createCategory(Map<String, dynamic> categoryMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories');
    final startTime = DateTime.now();

    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(categoryMap)}');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(categoryMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании категории');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет данные категории по её ID.
  Future<String> updateCategory(Map<String, dynamic> categoryMap, int categoryId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryId');
    final startTime = DateTime.now();

    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(categoryMap)}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(categoryMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении категории');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет категорию по её ID.
  Future<String> deleteCategory(int categoryID) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryID');
    final startTime = DateTime.now();

    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении категории');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
