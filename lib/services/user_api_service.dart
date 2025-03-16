import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с пользователями через REST API, используя пакет http.
class UserAPIService {
  final String baseUrl;

  UserAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, добавляется access token авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true, bool isMultipart = false}) async {
    final headers = <String, String>{};
    if (!isMultipart) {headers['Content-Type'] = 'application/json';}
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает всех пользователей.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении пользователей');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает пользователя по ID.
  Future<Map<String, dynamic>> getUserById(int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении пользователя');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создает нового пользователя. Если передан avatarFilePath – используется multipart-запрос, иначе JSON.
  Future<String> createUser(Map<String, dynamic> userMap, {String? avatarFilePath}) async {
    final uri = Uri.parse('$baseUrl/users');
    if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
      // Multipart-запрос с файлом аватара
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(await _getHeaders(auth: true, isMultipart: true));
      userMap.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarFilePath));
      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Пользователь создан';
        } else {
          final errorData = jsonDecode(response.body);
          throw ApiException(errorData['error'] ?? 'Ошибка при создании пользователя');
        }
      } catch (e) {
        rethrow;
      }
    } else {
      // JSON-запрос без файла
      final headers = await _getHeaders();
      try {
        final response = await http.post(uri, headers: headers, body: jsonEncode(userMap));
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Пользователь создан';
        } else {
          final errorData = jsonDecode(response.body);
          throw ApiException(errorData['error'] ?? 'Ошибка при создании пользователя');
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Обновляет данные пользователя.
  Future<String> updateUser(Map<String, dynamic> userMap, int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(userMap));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Пользователь обновлён';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении пользователя');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет пользователя по его ID.
  Future<String> deleteUser(int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Пользователь удалён';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении пользователя');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Авторизует пользователя (логин).
  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    final headers = await _getHeaders(auth: false);
    final uri = Uri.parse('$baseUrl/users/login');
    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(credentials));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при авторизации');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет Access Token с использованием refresh token.
  Future<String> refreshToken() async {
    final headers = await _getHeaders(auth: false);
    final uri = Uri.parse('$baseUrl/users/refresh-token');
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw ApiException('Отсутствует refresh token');
      }
      final requestBody = jsonEncode({'refreshToken': refreshToken});
      final response = await http.post(uri, headers: headers, body: requestBody);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('accessToken')) {
          return data['accessToken'] as String;
        } else {
          throw ApiException('Токен не получен при обновлении');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при обновлении токена');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Устанавливает аватар пользователя с использованием multipart-запроса.
  Future<String> setUserAvatar(int userId, String imagePath) async {
    final uri = Uri.parse('$baseUrl/users/$userId/setUserAvatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _getHeaders(auth: true, isMultipart: true));
    request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAvatar = data['avatar'];
        await AuthStorage.saveUserAvatar(newAvatar);
        return newAvatar;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при установке аватара');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает URL аватара пользователя.
  Future<String> getUserAvatar(int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users/$userId/getUserAvatar');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final avatarUrl = '$baseUrl/users/$userId/getUserAvatar';
        await AuthStorage.saveUserAvatar(avatarUrl);
        return avatarUrl;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении аватара');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет аватар пользователя.
  Future<String> deleteUserAvatar(int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/users/$userId/deleteUserAvatar');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthStorage.saveUserAvatar('/assets/user/no_image_user.png');
        return data['message'] ?? 'Аватар удалён';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при удалении аватара');
      }
    } catch (e) {
      rethrow;
    }
  }
}
