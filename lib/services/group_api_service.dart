import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/group.dart';

/// Сервис для работы с группами через REST API.
class GroupAPIService {
  final String baseUrl;

  GroupAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, добавляется токен авторизации.
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

  /// Получает список всех групп.
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/groups'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('GroupAPIService.getAllGroups: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('GroupAPIService.getAllGroups error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при получении групп');
    }
  }

  /// Получает группу по её ID.
  Future<Group> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/groups/$groupId'), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('GroupAPIService.getGroupById ($groupId): ${response.body}');
      return Group.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'GroupAPIService.getGroupById error ($groupId): ${response.body}');
      throw ApiException(errorData['error'] ??
          'Неизвестная ошибка при получении группы по ID');
    }
  }

  /// Создаёт новую группу.
  /// ID и дата создания не передаются, их генерирует сервер.
  Future<void> createGroup(Map<String, dynamic> groupMap) async {
    final headers = await _getHeaders();
    debugPrint('GroupAPIService.createGroup payload: ${jsonEncode(groupMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 201) {
      debugPrint('GroupAPIService.createGroup: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('GroupAPIService.createGroup error: ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при создании группы');
    }
  }

  /// Обновляет данные группы по её ID.
  Future<void> updateGroup(Map<String, dynamic> groupMap, int groupId) async {
    final headers = await _getHeaders();
    debugPrint(
        'GroupAPIService.updateGroup payload для groupId $groupId: ${jsonEncode(groupMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/groups/$groupId'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 200) {
      debugPrint('GroupAPIService.updateGroup ($groupId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'GroupAPIService.updateGroup error ($groupId): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при обновлении группы');
    }
  }

  /// Удаляет группу по её ID.
  Future<void> deleteGroup(int groupID) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupID'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      debugPrint('GroupAPIService.deleteGroup ($groupID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint(
          'GroupAPIService.deleteGroup error ($groupID): ${response.body}');
      throw ApiException(
          errorData['error'] ?? 'Неизвестная ошибка при удалении группы');
    }
  }
}
