import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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

/*─────────────────────────────────────────────────────────
 |  Создание пользователя (универсальная загрузка аватара)
 |  • Mobile – avatarFilePath
 |  • Web    – bytes + filename
 ─────────────────────────────────────────────────────────*/
  Future<String> createUser(Map<String, dynamic> userMap, {String? avatarFilePath, Uint8List? bytes, String? filename,}) async {
    final uri = Uri.parse('$baseUrl/users');

    // определяем, нужен ли multipart
    final needMultipart = kIsWeb
        ? (bytes != null && filename != null)
        : (avatarFilePath != null && avatarFilePath.isNotEmpty);

    // ─── compile-time + runtime валидация (только если файл нужен)
    assert(
    !needMultipart ||
        (kIsWeb
            ? (bytes != null && filename != null)
            : (avatarFilePath != null && avatarFilePath.isNotEmpty)),
    'Неверные параметры для multipart-запроса',
    );
    if (needMultipart) {
      if (kIsWeb && (bytes == null || filename == null)) {
        throw ArgumentError(
            'Для Web необходимо передать одновременно [bytes] и [filename].');
      }
      if (!kIsWeb &&
          (avatarFilePath == null || avatarFilePath.isEmpty)) {
        throw ArgumentError(
            'Для Mobile необходимо передать непустой [avatarFilePath].');
      }
    }

    // ─── JSON-ветка (без файла) ───
    if (!needMultipart) {
      final headers = await _getHeaders();
      final resp =
      await http.post(uri, headers: headers, body: jsonEncode(userMap));
      if (resp.statusCode == 201) {
        return (jsonDecode(resp.body))['message'] ?? 'Пользователь создан';
      }
      throw ApiException(
          (jsonDecode(resp.body))['error'] ?? 'Ошибка при создании пользователя');
    }

    // ─── multipart-ветка (с файлом) ───
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _getHeaders(auth: true, isMultipart: true))
      ..fields.addAll(userMap.map((k, v) => MapEntry(k, v.toString())));

    if (kIsWeb) {
      req.files
          .add(http.MultipartFile.fromBytes('avatar', bytes!, filename: filename));
    } else {
      req.files.add(await http.MultipartFile.fromPath('avatar', avatarFilePath!));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 201) {
      return (jsonDecode(resp.body))['message'] ?? 'Пользователь создан';
    }
    throw ApiException(
        (jsonDecode(resp.body))['error'] ?? 'Ошибка при создании пользователя');
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

/*─────────────────────────────────────────────────────────
 |  Установить/заменить аватар (Web + Mobile)
 |  • Mobile – imagePath
 |  • Web    – bytes + filename
 ─────────────────────────────────────────────────────────*/
  Future<String> setUserAvatar(int userId, {String? imagePath, Uint8List? bytes, String? filename,}) async {
    assert(
    kIsWeb
        ? (bytes != null && filename != null)
        : (imagePath != null && imagePath.isNotEmpty),
    'Передайте корректные параметры для текущей платформы',
    );

    if (kIsWeb && (bytes == null || filename == null)) {
      throw ArgumentError(
          'Для Web необходимо передать одновременно [bytes] и [filename].');
    }
    if (!kIsWeb && (imagePath == null || imagePath.isEmpty)) {
      throw ArgumentError(
          'Для Mobile необходимо передать непустой [imagePath].');
    }

    final uri = Uri.parse('$baseUrl/users/$userId/setUserAvatar');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _getHeaders(auth: true, isMultipart: true));

    if (kIsWeb) {
      req.files
          .add(http.MultipartFile.fromBytes('avatar', bytes!, filename: filename));
    } else {
      req.files.add(await http.MultipartFile.fromPath('avatar', imagePath!));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200) {
      final avatar = (jsonDecode(resp.body))['avatar'];
      await AuthStorage.saveUserAvatar(avatar);
      return avatar;
    }
    throw ApiException(
        (jsonDecode(resp.body))['error'] ?? 'Ошибка при установке аватара');
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
