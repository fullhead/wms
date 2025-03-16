import 'package:flutter/material.dart';
import 'package:wms/views/report/report_receive/report_receive_table.dart';
import 'package:wms/views/report/report_type.dart';

/// Виджет с 4 вкладками: День, Неделя, Месяц и Период.
/// Каждая вкладка содержит свою таблицу (ReportReceiveTable).
class ReportReceiveTabs extends StatelessWidget {
  final GlobalKey<ReportReceiveTableState> dailyKey;
  final GlobalKey<ReportReceiveTableState> weeklyKey;
  final GlobalKey<ReportReceiveTableState> monthlyKey;
  final GlobalKey<ReportReceiveTableState> intervalKey;

  const ReportReceiveTabs({
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
        ReportReceiveTable(key: dailyKey, reportType: ReportType.daily),
        ReportReceiveTable(key: weeklyKey, reportType: ReportType.weekly),
        ReportReceiveTable(key: monthlyKey, reportType: ReportType.monthly),
        ReportReceiveTable(key: intervalKey, reportType: ReportType.interval),
      ],
    );
  }
}
