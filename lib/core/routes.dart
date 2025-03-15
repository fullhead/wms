import 'package:flutter/material.dart';
import 'package:wms/views/authorization_view.dart';
import 'package:wms/views/dashboard/dashboard_view.dart';
import 'package:wms/views/group_view.dart';
import 'package:wms/views/user_view.dart';
import 'package:wms/views/category_view.dart';
import 'package:wms/views/product_view.dart';
import 'package:wms/views/receive/receive_view.dart';
import 'package:wms/views/issue/issue_view.dart';
import 'package:wms/views/warehouse_view.dart';
import 'package:wms/views/cell_view.dart';
import 'package:wms/views/report/report_view.dart';
import 'package:wms/views/personalization_view.dart';
import 'package:wms/views/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String authorization = '/auth';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String groups = '/groups';
  static const String categories = '/categories';
  static const String products = '/products';
  static const String receives = '/receives';
  static const String issues = '/issues';
  static const String warehouse = '/warehouse';
  static const String cells = '/cells';
  static const String receiptReports = '/receiptReports';
  static const String issueReports = '/issueReports';
  static const String personalization = '/personalization';

  // Возвращает набор маршрутов, доступных для заданного уровня допуска ("1", "2", "3")
  static Map<String, WidgetBuilder> getRoutesForRole(String role) {
    final routes = <String, WidgetBuilder>{
      splash: (context) => const SplashScreen(),
      authorization: (context) => const AuthorizationView(),
      personalization: (context) => const PersonalizationView(),
    };

    if (role == '1') {
      // Уровень 1: полный доступ
      routes.addAll({
        dashboard: (context) => const DashboardView(),
        users: (context) => const UserView(),
        groups: (context) => const GroupView(),
        categories: (context) => const CategoryView(),
        products: (context) => const ProductView(),
        receives: (context) => const ReceiveView(),
        issues: (context) => const IssueView(),
        warehouse: (context) => const WarehouseView(),
        cells: (context) => const CellView(),
        receiptReports: (context) => const ReportView(),
        issueReports: (context) => const ReportView(),
      });
    } else if (role == '2') {
      // Уровень 2: доступ только к управлению запасами и учёту запасов
      routes.addAll({
        receives: (context) => const ReceiveView(),
        issues: (context) => const IssueView(),
        warehouse: (context) => const WarehouseView(),
        cells: (context) => const CellView(),
      });
    } else if (role == '3') {
      // Уровень 3: доступ к панели управления и отчётам
      routes.addAll({
        dashboard: (context) => const DashboardView(),
        receiptReports: (context) => const ReportView(),
        issueReports: (context) => const ReportView(),
      });
    }
    return routes;
  }

  // Полный набор маршрутов без фильтрации (например, для администрирования)
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      authorization: (context) => const AuthorizationView(),
      dashboard: (context) => const DashboardView(),
      users: (context) => const UserView(),
      groups: (context) => const GroupView(),
      categories: (context) => const CategoryView(),
      products: (context) => const ProductView(),
      receives: (context) => const ReceiveView(),
      issues: (context) => const IssueView(),
      warehouse: (context) => const WarehouseView(),
      cells: (context) => const CellView(),
      receiptReports: (context) => const ReportView(),
      issueReports: (context) => const ReportView(),
      personalization: (context) => const PersonalizationView(),
    };
  }
}
