import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с унифицированными отчетами (приемка и выдача) через REST API.
class ReportAPIService {
  final String baseUrl;

  ReportAPIService({required this.baseUrl});

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

  /// Запрос дневного отчета
  Future<Map<String, dynamic>> getDailyReport(String type, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/daily?date=$date');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = _tryDecodeError(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении дневного отчета');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Запрос недельного отчета
  Future<Map<String, dynamic>> getWeeklyReport(String type, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/weekly?date=$date');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = _tryDecodeError(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении недельного отчета');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Запрос месячного отчета
  Future<Map<String, dynamic>> getMonthlyReport(String type, String year, String month) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/monthly?year=$year&month=$month');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = _tryDecodeError(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении месячного отчета');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Запрос отчета за произвольный интервал
  Future<Map<String, dynamic>> getIntervalReport(String type, String startDate, String endDate) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/interval?startDate=$startDate&endDate=$endDate');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = _tryDecodeError(response.body);
        throw ApiException(errorData['error'] ?? 'Ошибка при получении отчета за интервал');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Вспомогательная функция для безопасного парсинга body при ошибках.
  Map<String, dynamic> _tryDecodeError(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': body};
    }
  }
}
