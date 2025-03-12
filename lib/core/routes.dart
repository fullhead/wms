import 'package:flutter/material.dart';
import 'package:wms/views/auth/authorization_view.dart';
import 'package:wms/views/dashboard/dashboard_view.dart';
import 'package:wms/views/group/group_view.dart';
import 'package:wms/views/user/user_view.dart';
import 'package:wms/views/category/category_view.dart';
import 'package:wms/views/product/product_view.dart';
import 'package:wms/views/receive/receive_view.dart';
import 'package:wms/views/issue/issue_view.dart';
import 'package:wms/views/warehouse/warehouse_view.dart';
import 'package:wms/views/cell/cell_view.dart';
import 'package:wms/views/report/report_view.dart';
import 'package:wms/views/personalization/personalization_view.dart';
import 'package:wms/views/splash/splash_screen.dart';

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
