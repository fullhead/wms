import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/cell.dart';

/// Сервис для работы с ячейками через REST API.
class CellAPIService {
  final String baseUrl;

  CellAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если auth равен true, то добавляется токен авторизации.
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

  /// Получает список всех ячеек.
  Future<List<Map<String, dynamic>>> getAllCells() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/cells'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('CellAPIService.getAllCells: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CellAPIService.getAllCells error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячеек');
    }
  }

  /// Получает ячейку по её ID.
  Future<Cell> getCellById(int cellId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/cells/$cellId'), headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('CellAPIService.getCellById ($cellId): ${response.body}');
      return Cell.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CellAPIService.getCellById error ($cellId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении ячейки по ID');
    }
  }

  /// Создает новую ячейку.
  Future<String> createCell(Map<String, dynamic> cellMap) async {
    final headers = await _getHeaders();
    debugPrint('CellAPIService.createCell payload: ${jsonEncode(cellMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/cells'),
      headers: headers,
      body: jsonEncode(cellMap),
    );
    if (response.statusCode == 201) {
      debugPrint('CellAPIService.createCell response: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Ячейка создана';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CellAPIService.createCell error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании ячейки');
    }
  }

  /// Обновляет данные ячейки по её ID.
  Future<String> updateCell(Map<String, dynamic> cellMap, int cellId) async {
    final headers = await _getHeaders();
    debugPrint('CellAPIService.updateCell payload for cellId $cellId: ${jsonEncode(cellMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/cells/$cellId'),
      headers: headers,
      body: jsonEncode(cellMap),
    );
    if (response.statusCode == 200) {
      debugPrint('CellAPIService.updateCell response for cellId $cellId: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Ячейка обновлена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CellAPIService.updateCell error ($cellId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении ячейки');
    }
  }

  /// Удаляет ячейку по её ID.
  Future<String> deleteCell(int cellId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/cells/$cellId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      debugPrint('CellAPIService.deleteCell ($cellId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Ячейка удалена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('CellAPIService.deleteCell error ($cellId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении ячейки');
    }
  }
}
