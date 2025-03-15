import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

class DashboardAPIService {
  final String baseUrl;

  DashboardAPIService({required this.baseUrl});

  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
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

    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(
            errorData['error'] ?? 'Ошибка при получении статистики');
      }
    } catch (e, st) {
      debugPrint('[${DateTime.now().toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  /// Получает агрегированные данные мониторинга дашборда
  Future<Map<String, dynamic>> getMonitoring() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/dashboard/monitoring');

    final startTime = DateTime.now();
    debugPrint('[${startTime.toIso8601String()}] [GET] => $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final endTime = DateTime.now();
      debugPrint(
          '[${endTime.toIso8601String()}] [RESPONSE] => status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(
            errorData['error'] ?? 'Ошибка при получении мониторинга');
      }
    } catch (e, st) {
      debugPrint('[${DateTime.now().toIso8601String()}] [ERROR] => $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }
}
