import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с продукцией через REST API.
class ProductAPIService {
  final String baseUrl;

  ProductAPIService({required this.baseUrl});

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

  /// Получает список всей продукции.
  Future<List<Map<String, dynamic>>> getAllProduct() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает продукт по его ID.
  Future<Map<String, dynamic>> getProductById(int productId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products/$productId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении продукта по ID');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создает новую продукцию.
  Future<String> createProduct(Map<String, dynamic> productMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products');
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(productMap),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Продукция создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные продукта.
  Future<String> updateProduct(Map<String, dynamic> productMap, int productId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products/$productId');
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(productMap),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Продукция обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет продукт по его ID.
  Future<String> deleteProduct(int productID) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products/$productID');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Продукция удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Загружает изображение продукта.
  Future<String> uploadProductImage(String imagePath) async {
    final token = await AuthStorage.getAccessToken();
    final uri = Uri.parse('$baseUrl/products/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['path'];
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при загрузке изображения');
      }
    } catch (e) {
      rethrow;
    }
  }
}
