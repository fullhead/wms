import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с пользователями через REST API.
class UserAPIService {
  final String baseUrl;

  UserAPIService({required this.baseUrl});

  /// Формирует заголовки для запросов, добавляя токен авторизации при необходимости.
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

  /// Получает список всех пользователей.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    debugPrint('UserAPIService.getAllUsers: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.getAllUsers error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении пользователей');
    }
  }

  /// Получает данные пользователя по его ID.
  Future<Map<String, dynamic>> getUserById(int userId) async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    debugPrint('UserAPIService.getUserById ($userId): ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'UserAPIService.getUserById error ($userId): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении пользователя');
    }
  }

  /// Создает нового пользователя.
  Future<String> createUser(Map<String, dynamic> userMap) async {
    final headers = await _getHeaders();
    debugPrint('UserAPIService.createUser payload: ${jsonEncode(userMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    debugPrint('UserAPIService.createUser: ${response.body}');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь создан';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.createUser error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при создании пользователя');
    }
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(Map<String, dynamic> userMap, int userId) async {
    final headers = await _getHeaders();
    debugPrint(
        'UserAPIService.updateUser payload for userId $userId: ${jsonEncode(userMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    debugPrint('UserAPIService.updateUser ($userId): ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь обновлён';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.updateUser error ($userId): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при обновлении пользователя');
    }
  }

  /// Удаляет пользователя по его ID.
  Future<String> deleteUser(int userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'),
        headers: headers);
    debugPrint('UserAPIService.deleteUser ($userId): ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь удалён';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.deleteUser error ($userId): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Ошибка при удалении пользователя');
    }
  }

  /// Авторизует пользователя, отправляя его учетные данные.
  Future<Map<String, dynamic>> loginUser(
      Map<String, dynamic> credentials) async {
    final headers = await _getHeaders(auth: false);
    debugPrint('UserAPIService.loginUser payload: ${jsonEncode(credentials)}');
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: headers,
      body: jsonEncode(credentials),
    );
    debugPrint('UserAPIService.loginUser: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.loginUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при авторизации');
    }
  }

  /// Загружает аватар пользователя.
  Future<String> uploadUserAvatar(String imagePath) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/users/upload-avatar');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('UserAPIService.uploadUserAvatar: ${response.body}');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['path'];
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.uploadUserAvatar error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при загрузке аватара');
    }
  }
}
