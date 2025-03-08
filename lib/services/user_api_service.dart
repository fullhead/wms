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
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('UserAPIService.getAllUsers: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.getAllUsers error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при получении пользователей');
    }
  }

  /// Получает данные пользователя по его ID.
  Future<Map<String, dynamic>> getUserById(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.getUserById ($userId): ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.getUserById error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при получении пользователя');
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
    if (response.statusCode == 201) {
      debugPrint('UserAPIService.createUser: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь создан';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.createUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при создании пользователя');
    }
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(Map<String, dynamic> userMap, int userId) async {
    final headers = await _getHeaders();
    debugPrint('UserAPIService.updateUser payload for userId $userId: ${jsonEncode(userMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.updateUser ($userId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь обновлён';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.updateUser error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при обновлении пользователя');
    }
  }

  /// Удаляет пользователя по его ID.
  Future<String> deleteUser(int userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.deleteUser ($userId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Пользователь удалён';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.deleteUser error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при удалении пользователя');
    }
  }

  /// Авторизует пользователя, отправляя его учетные данные.
  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    final headers = await _getHeaders(auth: false);
    debugPrint('UserAPIService.loginUser payload: ${jsonEncode(credentials)}');
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: headers,
      body: jsonEncode(credentials),
    );
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.loginUser: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.loginUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при авторизации');
    }
  }

  /// Устанавливает аватар пользователя.
  /// Отправляет POST запрос с multipart/form-data на /users/{id}/setUserAvatar.
  Future<String> setUserAvatar(int userId, String imagePath) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/users/$userId/setUserAvatar');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.setUserAvatar: ${response.body}');
      final data = jsonDecode(response.body);
      final newAvatar = data['avatar'];
      // Кэшируем новый URL аватара
      await AuthStorage.saveUserAvatar(newAvatar);
      return newAvatar;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.setUserAvatar error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при установке аватара');
    }
  }

  /// Получает аватар пользователя.
  /// Отправляет GET запрос на /users/{id}/getUserAvatar и возвращает полный URL изображения.
  Future<String> getUserAvatar(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/getUserAvatar'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.getUserAvatar ($userId) успешно получен');
      // Формируем URL, по которому изображение доступно
      final avatarUrl = '$baseUrl/users/$userId/getUserAvatar';
      await AuthStorage.saveUserAvatar(avatarUrl);
      return avatarUrl;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.getUserAvatar error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при получении аватара');
    }
  }

  /// Удаляет аватар пользователя.
  /// Отправляет DELETE запрос на /users/{id}/deleteUserAvatar.
  Future<String> deleteUserAvatar(int userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId/deleteUserAvatar'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('UserAPIService.deleteUserAvatar ($userId): ${response.body}');
      final data = jsonDecode(response.body);
      // Кэшируем дефолтный аватар
      await AuthStorage.saveUserAvatar('/assets/user/no_image_user.png');
      return data['message'] ?? 'Аватар удалён';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('UserAPIService.deleteUserAvatar error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Ошибка при удалении аватара');
    }
  }

  /// Обновляет токен пользователя.
  Future<String> refreshToken() async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/users/refresh-token'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('token')) {
        return data['token'] as String;
      } else {
        throw ApiException('Токен не получен при обновлении');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw ApiException(errorData['error'] ?? 'Ошибка при обновлении токена');
    }
  }
}
