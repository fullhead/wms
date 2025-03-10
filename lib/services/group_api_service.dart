import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает список всех групп.
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('GroupAPIService.getAllGroups error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении групп');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Group.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('GroupAPIService.getGroupById error ($groupId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении группы по ID');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Создаёт новую группу.
  Future<String> createGroup(Map<String, dynamic> groupMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [POST] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(groupMap)}');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(groupMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 201) {
        debugPrint('GroupAPIService.createGroup: ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа создана';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('GroupAPIService.createGroup error: ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании группы');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Обновляет данные группы по её ID.
  Future<String> updateGroup(Map<String, dynamic> groupMap, int groupId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupId');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [PUT] => $uri');
    debugPrint('[HEADERS] => $headers');
    debugPrint('[BODY] => ${jsonEncode(groupMap)}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(groupMap),
      );
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('GroupAPIService.updateGroup ($groupId): ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('GroupAPIService.updateGroup error ($groupId): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении группы');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Удаляет группу по её ID.
  Future<String> deleteGroup(int groupID) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/groups/$groupID');
    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [DELETE] => $uri');
    debugPrint('[HEADERS] => $headers');

    try {
      final response = await http.delete(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint('[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('GroupAPIService.deleteGroup ($groupID): ${response.body}');
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Группа удалена';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('GroupAPIService.deleteGroup error ($groupID): ${response.body}');
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении группы');
      }
    } catch (e, st) {
      final errorTime = DateTime.now();
      debugPrint('[${errorTime.toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
