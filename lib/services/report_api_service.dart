import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/utils.dart';

/// Сервис для работы с унифицированными отчетами (и приход, и выдачи) через REST API.
class ReportAPIService {
  final String baseUrl;

  ReportAPIService({required this.baseUrl});

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

  /// Запрос дневного отчета: GET /report/:type/daily?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getDailyReport(String type, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/daily?date=$date');
    debugPrint('[GET] $uri, HEADERS: $headers');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = _tryDecodeError(response.body);
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении дневного отчета');
    }
  }

  /// Запрос недельного отчета: GET /report/:type/weekly?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getWeeklyReport(String type, String date) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/report/$type/weekly?date=$date');
    debugPrint('[GET] $uri, HEADERS: $headers');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = _tryDecodeError(response.body);
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении недельного отчета');
    }
  }

  /// Запрос месячного отчета: GET /report/:type/monthly?year=YYYY&month=MM
  Future<Map<String, dynamic>> getMonthlyReport(String type, String year, String month) async {
    final headers = await _getHeaders();
    final uri =
        Uri.parse('$baseUrl/report/$type/monthly?year=$year&month=$month');
    debugPrint('[GET] $uri, HEADERS: $headers');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = _tryDecodeError(response.body);
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении месячного отчета');
    }
  }

  /// Запрос отчета за произвольный интервал:
  /// GET /report/:type/interval?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
  Future<Map<String, dynamic>> getIntervalReport(String type, String startDate, String endDate) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/report/$type/interval?startDate=$startDate&endDate=$endDate');
    debugPrint('[GET] $uri, HEADERS: $headers');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = _tryDecodeError(response.body);
      throw ApiException(
          errorData['error'] ?? 'Ошибка при получении отчета за интервал');
    }
  }

  /// Вспомогательная функция, чтобы безопасно распарсить body при ошибках
  Map<String, dynamic> _tryDecodeError(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': body};
    }
  }
}
