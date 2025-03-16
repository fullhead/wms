import 'package:wms/models/report.dart';
import 'package:wms/services/report_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

/// Репозиторий для работы с отчетами через ReportAPIService, нужно только передавать type = 'receives' или 'issues'.
class ReportRepository {
  final ReportAPIService reportAPIService;
  final SessionManager _sessionManager;

  ReportRepository(
      {ReportAPIService? reportAPIService, required String baseUrl})
      : reportAPIService =reportAPIService ?? ReportAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  /// Получает дневной отчет и возвращает Map
  Future<Map<String, dynamic>> fetchDailyReport(String type, String date) async {
    await _sessionManager.validateSession();
    final response = await reportAPIService.getDailyReport(type, date);
    final List<dynamic> data = response['data'] ?? [];
    response['data'] = data.map((json) => ReportEntry.fromJson(json)).toList();
    return response;
  }

  /// Получает недельный отчет.
  Future<Map<String, dynamic>> fetchWeeklyReport(String type, String date) async {
    await _sessionManager.validateSession();
    final response = await reportAPIService.getWeeklyReport(type, date);
    final List<dynamic> data = response['data'] ?? [];
    response['data'] = data.map((json) => ReportEntry.fromJson(json)).toList();
    return response;
  }

  /// Получает месячный отчет.
  Future<Map<String, dynamic>> fetchMonthlyReport(String type, String year, String month) async {
    await _sessionManager.validateSession();
    final response = await reportAPIService.getMonthlyReport(type, year, month);
    final List<dynamic> data = response['data'] ?? [];
    response['data'] = data.map((json) => ReportEntry.fromJson(json)).toList();
    return response;
  }

  /// Получает отчет за произвольный интервал.
  Future<Map<String, dynamic>> fetchIntervalReport(String type, String startDate, String endDate) async {
    await _sessionManager.validateSession();
    final response = await reportAPIService.getIntervalReport(type, startDate, endDate);
    final List<dynamic> data = response['data'] ?? [];
    response['data'] = data.map((json) => ReportEntry.fromJson(json)).toList();
    return response;
  }
}
