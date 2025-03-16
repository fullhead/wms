import 'package:wms/core/constants.dart';
import 'package:wms/models/dashboard.dart';
import 'package:wms/repositories/dashboard_repository.dart';

/// Презентер для работы с панелью управления.
class DashboardPresenter {
  final DashboardRepository _dashboardRepository;

  DashboardPresenter({DashboardRepository? dashboardRepository})
      : _dashboardRepository = dashboardRepository ?? DashboardRepository(baseUrl: AppConstants.apiBaseUrl);

  /// Получает статистику для панели управления.
  Future<DashboardStatistics> fetchStatistics() async {
    return await _dashboardRepository.getStatistics();
  }

  /// Получает мониторинг для панели управления.
  Future<DashboardMonitoring> fetchMonitoring() async {
    return await _dashboardRepository.getMonitoring();
  }
}
