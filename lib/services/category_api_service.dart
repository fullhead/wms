import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/category.dart' as wms_category;

/// Сервис для работы с категориями через REST API.
class CategoryAPIService {
  final String baseUrl;

  CategoryAPIService({required this.baseUrl});

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

  /// Получает список всех категорий.
  Future<List<Map<String, dynamic>>> getAllCategory() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories');
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категорий');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает категорию по её ID.
  Future<wms_category.Category> getCategoryById(int categoryId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return wms_category.Category.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категории по ID');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создает новую категорию.
  Future<String> createCategory(Map<String, dynamic> categoryMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories');
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(categoryMap),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании категории');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные категории по её ID.
  Future<String> updateCategory(Map<String, dynamic> categoryMap, int categoryId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryId');
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(categoryMap),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении категории');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет категорию по её ID.
  Future<String> deleteCategory(int categoryID) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/categories/$categoryID');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Категория удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(
            errorData['error'] ?? 'Неизвестная ошибка при удалении категории');
      }
    } catch (e) {
      rethrow;
    }
  }
}
