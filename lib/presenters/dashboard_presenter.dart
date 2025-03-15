import 'package:wms/core/constants.dart';
import 'package:wms/models/dashboard.dart';
import 'package:wms/repositories/dashboard_repository.dart';

class DashboardPresenter {
  final DashboardRepository _dashboardRepository;

  DashboardPresenter({DashboardRepository? dashboardRepository})
      : _dashboardRepository = dashboardRepository ??
      DashboardRepository(baseUrl: AppConstants.apiBaseUrl);

  Future<DashboardStatistics> fetchStatistics() async {
    return await _dashboardRepository.getStatistics();
  }

  Future<DashboardMonitoring> fetchMonitoring() async {
    return await _dashboardRepository.getMonitoring();
  }
}
