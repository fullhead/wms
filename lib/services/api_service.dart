import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/models/group.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';

class APIService {
  /// Базовый URL серверного API.
  final String baseUrl;

  APIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, то добавляется токен авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---------------------------
  // Методы для работы с группами
  // ---------------------------

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/groups'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllGroups: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllGroups error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении групп');
    }
  }

  Future<Group> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/groups/$groupId'), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('getGroupById ($groupId): ${response.body}');
      return Group.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getGroupById error ($groupId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении группы по ID');
    }
  }

  /// Создание группы (ID не передаём, бэкенд генерирует его сам).
  Future<void> createGroup(Map<String, dynamic> groupMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createGroup payload: ${jsonEncode(groupMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 201) {
      debugPrint('createGroup: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createGroup error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании группы');
    }
  }

  /// Обновление группы: ID не берём из JSON, а передаём отдельным параметром.
  Future<void> updateGroup(Map<String, dynamic> groupMap, int groupId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateGroup payload for groupId $groupId: ${jsonEncode(groupMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/groups/$groupId'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 200) {
      debugPrint('updateGroup ($groupId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateGroup error ($groupId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении группы');
    }
  }

  Future<void> deleteGroup(int groupID) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupID'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      debugPrint('deleteGroup ($groupID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteGroup error ($groupID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении группы');
    }
  }

  // ------------------------------
  // Методы для работы с пользователями
  // ------------------------------

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllUsers: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllUsers error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении пользователей');
    }
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('getUserById ($userId): ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getUserById error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении пользователя');
    }
  }

  Future<void> createUser(Map<String, dynamic> userMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createUser payload: ${jsonEncode(userMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    if (response.statusCode == 201) {
      debugPrint('createUser: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании пользователя');
    }
  }

  Future<void> updateUser(Map<String, dynamic> userMap, int userId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateUser payload for userId $userId: ${jsonEncode(userMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    if (response.statusCode == 200) {
      debugPrint('updateUser ($userId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateUser error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении пользователя');
    }
  }

  Future<void> deleteUser(int userID) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userID'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('deleteUser ($userID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteUser error ($userID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении пользователя');
    }
  }

  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: await _getHeaders(auth: false),
      body: jsonEncode(credentials),
    );
    if (response.statusCode == 200) {
      debugPrint('loginUser: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('loginUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка авторизации');
    }
  }
}
