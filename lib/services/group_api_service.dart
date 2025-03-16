import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/group.dart';

/// Сервис для работы с группами через REST API.
class GroupAPIService {
  final String baseUrl;

  GroupAPIService({required this.baseUrl});

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

  /// Получает список всех групп.
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении групп');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Group.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении группы по ID');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создаёт новую группу.
  Future<String> createGroup(Map<String, dynamic> groupMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups');
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(groupMap),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании группы');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные группы по её ID.
  Future<String> updateGroup(Map<String, dynamic> groupMap, int groupId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(groupMap),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении группы');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет группу по её ID.
  Future<String> deleteGroup(int groupID) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupID');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении группы');
      }
    } catch (e) {
      rethrow;
    }
  }
}
