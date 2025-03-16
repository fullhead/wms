import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wms/models/report.dart';
import 'package:wms/views/report/report_issue/report_issue_pdf_generator.dart';
import 'package:wms/views/report/report_issue/report_issue_pdf_preview_screen.dart';
import 'package:wms/views/report/report_issue/report_issue_table.dart';
import 'package:wms/views/report/report_issue/report_issue_tabs.dart';
import 'package:wms/views/report/report_type.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/presenters/personalization_presenter.dart';

/// Экран "Отчеты по выдачам", аналогичен ReportReceiveView, но для issues.
class ReportIssueView extends StatefulWidget {
  const ReportIssueView({super.key});

  @override
  State<ReportIssueView> createState() => _ReportIssueViewState();
}

class _ReportIssueViewState extends State<ReportIssueView> {
  // Ключи для вкладок
  final _dailyKey = GlobalKey<ReportIssueTableState>();
  final _weeklyKey = GlobalKey<ReportIssueTableState>();
  final _monthlyKey = GlobalKey<ReportIssueTableState>();
  final _intervalKey = GlobalKey<ReportIssueTableState>();

  // Данные о пользователе
  String _responsibleName = '';
  String _position = '';

  final _personalizationPresenter = PersonalizationPresenter();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Загружаем пользователя (ФИО и должность).
  Future<void> _loadCurrentUser() async {
    final user = await _personalizationPresenter.getCurrentUser();
    if (mounted) {
      setState(() {
        _responsibleName = user.userFullname;
        _position = user.userGroup.groupName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (BuildContext builderContext) {
          return Scaffold(
            drawer: const WmsDrawer(),
            appBar: AppBar(
              title: const Text(
                'Отчеты по выдачам',
                style: TextStyle(color: Colors.deepOrange),
              ),
              actions: [
                IconButton(
                  tooltip: 'Предварительный просмотр',
                  icon: const Icon(Icons.remove_red_eye),
                  onPressed: () => _onPreviewPressed(builderContext),
                ),
                IconButton(
                  tooltip: 'Поделиться',
                  icon: const Icon(Icons.share),
                  onPressed: () => _onSharePressed(builderContext),
                ),
                IconButton(
                  tooltip: 'Скачать',
                  icon: const Icon(Icons.download),
                  onPressed: () => _onDownloadPressed(builderContext),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ReportIssueTabs(
                      dailyKey: _dailyKey,
                      weeklyKey: _weeklyKey,
                      monthlyKey: _monthlyKey,
                      intervalKey: _intervalKey,
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
                tabs: [
                  Tab(icon: Icon(Icons.looks_one), text: 'День'),
                  Tab(icon: Icon(Icons.calendar_view_week), text: 'Неделя'),
                  Tab(icon: Icon(Icons.calendar_view_month), text: 'Месяц'),
                  Tab(icon: Icon(Icons.date_range), text: 'Период'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Определяет, какая вкладка активна, и возвращает её тип и данные.
  (ReportType, List<ReportEntry>, Map<String, dynamic>?) _getCurrentReportData(
      BuildContext builderContext,
      ) {
    final tabIndex = DefaultTabController.of(builderContext).index;
    ReportIssueTableState? state;
    switch (tabIndex) {
      case 0:
        state = _dailyKey.currentState;
        break;
      case 1:
        state = _weeklyKey.currentState;
        break;
      case 2:
        state = _monthlyKey.currentState;
        break;
      case 3:
        state = _intervalKey.currentState;
        break;
    }
    if (state == null) {
      return (ReportType.daily, [], null);
    }
    return (
    state.reportType,
    state.getCurrentData(),
    state.getCurrentResponse()
    );
  }

  /// Готовит заголовок для PDF (одна и та же функция, что в таблице),
  String _buildPdfTitle(ReportType type, Map<String, dynamic>? response) {
    if (response == null) {
      return 'Отчет (нет данных)';
    }
    return buildReceiveReportTitle(type, response);
  }

  /// Формируем "умное" имя PDF-файла для "issues".
  String _buildPdfFileName(ReportType type, Map<String, dynamic>? response) {
    if (response == null) {
      return 'report_issues_no_data.pdf';
    }
    switch (type) {
      case ReportType.daily:
        final date = response['date'] ?? 'unknown';
        return 'report_daily_issues_$date.pdf';

      case ReportType.weekly:
        final weekStr = response['week'] ?? 'week_unknown';
        if (weekStr is String && weekStr.contains(' от ') && weekStr.contains(' до ')) {
          final parts = weekStr.split(' ');
          if (parts.length >= 5) {
            final start = parts[2].trim();
            final end = parts[4].trim();
            return 'report_weekly_issues_${start}_$end.pdf';
          }
        }
        return 'report_weekly_issues_unknown.pdf';

      case ReportType.monthly:
        final year = response['year']?.toString() ?? '0000';
        final monthRaw = (response['month'] ?? '').toString();
        return 'report_monthly_issues_$year-$monthRaw.pdf';

      case ReportType.interval:
        final start = response['startDate'] ?? 'start';
        final end = response['endDate'] ?? 'end';
        return 'report_interval_issues_${start}_$end.pdf';
    }
  }

  /// Предварительный просмотр PDF
  Future<void> _onPreviewPressed(BuildContext builderContext) async {
    final (type, data, response) = _getCurrentReportData(builderContext);
    if (data.isEmpty) {
      _showNoDataSnackBar();
      return;
    }
    final title = _buildPdfTitle(type, response);
    final pdfBytes = await generatePdfIssueReport(
      title,
      data,
      responsibleName: _responsibleName,
      position: _position,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportIssuePdfPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  /// Поделиться PDF
  Future<void> _onSharePressed(BuildContext builderContext) async {
    final (type, data, response) = _getCurrentReportData(builderContext);
    if (data.isEmpty) {
      _showNoDataSnackBar();
      return;
    }
    final title = _buildPdfTitle(type, response);
    final pdfBytes = await generatePdfIssueReport(
      title,
      data,
      responsibleName: _responsibleName,
      position: _position,
    );
    final suggestedName = _buildPdfFileName(type, response);

    await Printing.sharePdf(bytes: pdfBytes, filename: suggestedName);
  }

  /// Скачать PDF
  Future<void> _onDownloadPressed(BuildContext builderContext) async {
    final (type, data, response) = _getCurrentReportData(builderContext);
    if (data.isEmpty) {
      _showNoDataSnackBar();
      return;
    }
    final title = _buildPdfTitle(type, response);
    final pdfBytes = await generatePdfIssueReport(
      title,
      data,
      responsibleName: _responsibleName,
      position: _position,
    );
    final suggestedName = _buildPdfFileName(type, response);

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Выберите место для сохранения PDF-отчёта',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes,
      );

      if (savedPath == null) {
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл успешно сохранён: $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  void _showNoDataSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Нет данных для формирования отчёта')),
    );
  }
}
