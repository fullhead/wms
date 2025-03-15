import 'package:wms/models/dashboard.dart';
import 'package:wms/services/dashboard_api_service.dart';
import 'package:wms/core/session/session_manager.dart';

class DashboardRepository {
  final DashboardAPIService dashboardAPIService;
  final SessionManager _sessionManager;

  DashboardRepository({
    DashboardAPIService? dashboardAPIService,
    required String baseUrl,
  })  : dashboardAPIService =
      dashboardAPIService ?? DashboardAPIService(baseUrl: baseUrl),
        _sessionManager = SessionManager();

  Future<DashboardStatistics> getStatistics() async {
    await _sessionManager.validateSession();
    final json = await dashboardAPIService.getStatistics();
    return DashboardStatistics.fromJson(json);
  }

  Future<DashboardMonitoring> getMonitoring() async {
    await _sessionManager.validateSession();
    final json = await dashboardAPIService.getMonitoring();
    return DashboardMonitoring.fromJson(json);
  }
}
