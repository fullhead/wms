import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с продукцией через REST API.
class ProductAPIService {
  final String baseUrl;

  ProductAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов. Если [auth] == true, добавляет токен авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Получает список всей продукции.
  Future<List<Map<String, dynamic>>> getAllProduct() async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/products'), headers: headers);
    debugPrint('ProductAPIService.getAllProduct: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('ProductAPIService.getAllProduct error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при получении продукции');
    }
  }

  /// Получает продукт по его ID.
  Future<Map<String, dynamic>> getProductById(int productId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/products/$productId'),
        headers: headers);
    debugPrint(
        'ProductAPIService.getProductById ($productId): ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'ProductAPIService.getProductById error ($productId): ${response.body}');
      throw ApiException(errorData['error'] ??
          'Неизвестная ошибка при получении продукта по ID');
    }
  }

  /// Создает новую продукцию.
  Future<String> createProduct(Map<String, dynamic> productMap) async {
    final headers = await _getHeaders();
    debugPrint(
        'ProductAPIService.createProduct payload: ${jsonEncode(productMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: headers,
      body: jsonEncode(productMap),
    );
    if (response.statusCode == 201) {
      debugPrint('ProductAPIService.createProduct: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция создана';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('ProductAPIService.createProduct error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при создании продукции');
    }
  }

  /// Обновляет данные продукта.
  Future<String> updateProduct(
      Map<String, dynamic> productMap, int productId) async {
    final headers = await _getHeaders();
    debugPrint(
        'ProductAPIService.updateProduct payload for productId $productId: ${jsonEncode(productMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
      body: jsonEncode(productMap),
    );
    if (response.statusCode == 200) {
      debugPrint(
          'ProductAPIService.updateProduct ($productId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция обновлена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'ProductAPIService.updateProduct error ($productId): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при обновлении продукции');
    }
  }

  /// Удаляет продукт по его ID.
  Future<String> deleteProduct(int productID) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl/products/$productID'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint(
          'ProductAPIService.deleteProduct ($productID): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция удалена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'ProductAPIService.deleteProduct error ($productID): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при удалении продукции');
    }
  }

  /// Загружает изображение продукта.
  Future<String> uploadProductImage(String imagePath) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/products/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201) {
      debugPrint('ProductAPIService.uploadProductImage: ${response.body}');
      final data = jsonDecode(response.body);
      return data['path'];
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'ProductAPIService.uploadProductImage error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при загрузке изображения');
    }
  }
}
