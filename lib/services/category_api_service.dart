import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/category.dart' as wms_category;

/// Сервис для работы с категориями через REST API.
class CategoryAPIService {
  final String baseUrl;

  CategoryAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если auth равен true, то добавляется токен авторизации.
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

  /// Получает список всех категорий.
  Future<List<Map<String, dynamic>>> getAllCategory() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('CategoryAPIService.getAllCategory: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CategoryAPIService.getAllCategory error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категорий');
    }
  }

  /// Получает категорию по её ID.
  Future<wms_category.Category> getCategoryById(int categoryId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId'), headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('CategoryAPIService.getCategoryById ($categoryId): ${response.body}');
      return wms_category.Category.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CategoryAPIService.getCategoryById error ($categoryId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категории по ID');
    }
  }

  /// Создает новую категорию.
  Future<String> createCategory(Map<String, dynamic> categoryMap) async {
    final headers = await _getHeaders();
    debugPrint('CategoryAPIService.createCategory payload: ${jsonEncode(categoryMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: jsonEncode(categoryMap),
    );
    if (response.statusCode == 201) {
      debugPrint('CategoryAPIService.createCategory response: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Категория создана';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CategoryAPIService.createCategory error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании категории');
    }
  }

  /// Обновляет данные категории по её ID.
  Future<String> updateCategory(Map<String, dynamic> categoryMap, int categoryId) async {
    final headers = await _getHeaders();
    debugPrint('CategoryAPIService.updateCategory payload for categoryId $categoryId: ${jsonEncode(categoryMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: headers,
      body: jsonEncode(categoryMap),
    );
    if (response.statusCode == 200) {
      debugPrint('CategoryAPIService.updateCategory response for categoryId $categoryId: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Категория обновлена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CategoryAPIService.updateCategory error ($categoryId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении категории');
    }
  }

  /// Удаляет категорию по её ID.
  Future<String> deleteCategory(int categoryID) async {
    final headers = await _getHeaders();
    final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryID'),
        headers: headers
    );
    if (response.statusCode == 200) {
      debugPrint('CategoryAPIService.deleteCategory ($categoryID): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Категория удалена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CategoryAPIService.deleteCategory error ($categoryID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении категории');
    }
  }
}
