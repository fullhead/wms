import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/cell.dart';

/// Сервис для работы с ячейками через REST API.
class CellAPIService {
  final String baseUrl;

  CellAPIService({required this.baseUrl});

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

  /// Получает список всех ячеек.
  Future<List<Map<String, dynamic>>> getAllCells() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячеек');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает ячейку по её ID.
  Future<Cell> getCellById(int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Cell.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячейки по ID');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создает новую ячейку.
  Future<String> createCell(Map<String, dynamic> cellMap) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells');
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(cellMap),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка создана';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании ячейки');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновляет данные ячейки по её ID.
  Future<String> updateCell(Map<String, dynamic> cellMap, int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(cellMap),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка обновлена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении ячейки');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет ячейку по её ID.
  Future<String> deleteCell(int cellId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/cells/$cellId');
    try {
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Ячейка удалена';
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении ячейки');
      }
    } catch (e) {
      rethrow;
    }
  }
}
