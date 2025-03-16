import 'package:wms/repositories/report_repository.dart';
import 'package:wms/core/constants.dart';

/// Презентер для управления отчетами.
class ReportPresenter {
  final ReportRepository _reportRepository;

  /// Можно указать baseUrl вручную или брать из AppConstants.apiBaseUrl
  ReportPresenter({ReportRepository? reportRepository})
      : _reportRepository = reportRepository ?? ReportRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Получает дневной отчет по дате.
  Future<Map<String, dynamic>> getDailyReport(String type, String date) async {
    return await _reportRepository.fetchDailyReport(type, date);
  }

  /// Получает недельный отчет.
  Future<Map<String, dynamic>> getWeeklyReport(String type, String date) async {
    return await _reportRepository.fetchWeeklyReport(type, date);
  }

  /// Получает месячный отчет по году и месяцу.
  Future<Map<String, dynamic>> getMonthlyReport(String type, String year, String month) async {
    return await _reportRepository.fetchMonthlyReport(type, year, month);
  }

  /// Получает отчет за произвольный интервал.
  Future<Map<String, dynamic>> getIntervalReport(String type, String startDate, String endDate) async {
    return await _reportRepository.fetchIntervalReport(
        type, startDate, endDate);
  }
}
