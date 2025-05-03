import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Получает список всей продукции (+ названия категорий).
  Future<List<Map<String, dynamic>>> getAllProduct() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products?withCategory=true');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(
            errorData['error'] ?? 'Неизвестная ошибка при получении продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает продукт по его ID (+ название категории).
  Future<Map<String, dynamic>> getProductById(int productId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/products/$productId?withCategory=true');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ??
            'Неизвестная ошибка при получении продукта по ID');
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
        throw ApiException(
            errorData['error'] ?? 'Неизвестная ошибка при создании продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные продукта.
  Future<String> updateProduct(
      Map<String, dynamic> productMap, int productId) async {
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
        throw ApiException(errorData['error'] ??
            'Неизвестная ошибка при обновлении продукции');
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
        throw ApiException(
            errorData['error'] ?? 'Неизвестная ошибка при удалении продукции');
      }
    } catch (e) {
      rethrow;
    }
  }

  /*─────────────────────────────────────────────────────────
 |  Загрузка изображения продукта (Web + Mobile)
 |  • Mobile – передаём [imagePath]
 |  • Web    – передаём [bytes] и [filename]
 ─────────────────────────────────────────────────────────*/
  Future<String> uploadProductImage({
    String? imagePath,
    Uint8List? bytes,
    String? filename,
  }) async {
    // ─────────── проверка параметров ───────────
    assert(
    kIsWeb
        ? (bytes != null && filename != null)
        : (imagePath != null && imagePath.isNotEmpty),
    'Передайте корректные параметры для текущей платформы',
    );

    // дополнительная проверка, чтобы ловить ошибки и в релиз-сборках
    if (kIsWeb) {
      if (bytes == null || filename == null) {
        throw ArgumentError(
            'Для Web необходимо передать оба параметра: [bytes] и [filename].');
      }
    } else {
      if (imagePath == null || imagePath.isEmpty) {
        throw ArgumentError(
            'Для Mobile необходимо передать непустой параметр [imagePath].');
      }
    }

    // ─────────── формируем запрос ───────────
    final token = await AuthStorage.getAccessToken();
    final uri   = Uri.parse('$baseUrl/products/upload');
    final req   = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    if (kIsWeb) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes!,
          filename: filename,
        ),
      );
    } else {
      req.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath!,
        ),
      );
    }

    // ─────────── отправляем ───────────
    final streamed = await req.send();
    final resp     = await http.Response.fromStream(streamed);

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['path'] as String?) ?? '';
    }

    final err = jsonDecode(resp.body) as Map<String, dynamic>;
    throw ApiException(err['error'] ?? 'Ошибка при загрузке изображения');
  }

}
