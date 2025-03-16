import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с панелью управления через REST API.
class DashboardAPIService {
  final String baseUrl;

  DashboardAPIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, добавляется access token авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Получает агрегированную статистику дашборда
  Future<Map<String, dynamic>> getStatistics() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/dashboard/statistics');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении статистики');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получает агрегированные данные мониторинга дашборда
  Future<Map<String, dynamic>> getMonitoring() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/dashboard/monitoring');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении мониторинга');
      }
    } catch (e) {
      rethrow;
    }
  }
}
