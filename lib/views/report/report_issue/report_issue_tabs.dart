import 'package:flutter/material.dart';
import 'package:wms/views/report/report_issue/report_issue_table.dart';
import 'package:wms/views/report/report_type.dart';

/// Виджет с 4 вкладками: День, Неделя, Месяц и Период (для issues).
class ReportIssueTabs extends StatelessWidget {
  final GlobalKey<ReportIssueTableState> dailyKey;
  final GlobalKey<ReportIssueTableState> weeklyKey;
  final GlobalKey<ReportIssueTableState> monthlyKey;
  final GlobalKey<ReportIssueTableState> intervalKey;

  const ReportIssueTabs({
    super.key,
    required this.dailyKey,
    required this.weeklyKey,
    required this.monthlyKey,
    required this.intervalKey,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        ReportIssueTable(key: dailyKey, reportType: ReportType.daily),
        ReportIssueTable(key: weeklyKey, reportType: ReportType.weekly),
        ReportIssueTable(key: monthlyKey, reportType: ReportType.monthly),
        ReportIssueTable(key: intervalKey, reportType: ReportType.interval),
      ],
    );
  }
}
