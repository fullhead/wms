import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms/models/report.dart';
import 'package:wms/presenters/report_presenter.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/views/report/report_type.dart';

class ReportReceiveTable extends StatefulWidget {
  final ReportType reportType;
  const ReportReceiveTable({super.key, required this.reportType});

  @override
  ReportReceiveTableState createState() => ReportReceiveTableState();
}

class ReportReceiveTableState extends State<ReportReceiveTable> {
  late Future<Map<String, dynamic>> _reportFuture;
  final ReportPresenter _presenter = ReportPresenter();

  // Храним текущие записи отчёта (для передачи вовне)
  List<ReportEntry> _currentData = [];
  // Храним полный ответ backend (для заголовков PDF и пр.)
  Map<String, dynamic>? _currentResponse;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.reportType == ReportType.interval) {
      final now = DateTime.now();
      // По умолчанию интервал - текущий месяц
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    }
    _loadReport();
  }

  /// Запрашивает данные отчёта в зависимости от типа.
  void _loadReport() {
    final now = DateTime.now();
    switch (widget.reportType) {
      case ReportType.daily:
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        _reportFuture = _presenter.getDailyReport('receives', dateStr);
        break;

      case ReportType.weekly:
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        _reportFuture = _presenter.getWeeklyReport('receives', dateStr);
        break;

      case ReportType.monthly:
        final year = DateFormat('yyyy').format(now);
        final month = DateFormat('MM').format(now);
        _reportFuture = _presenter.getMonthlyReport('receives', year, month);
        break;

      case ReportType.interval:
        if (_startDate != null && _endDate != null) {
          final start = DateFormat('yyyy-MM-dd').format(_startDate!);
          final end = DateFormat('yyyy-MM-dd').format(_endDate!);
          _reportFuture = _presenter.getIntervalReport('receives', start, end);
        } else {
          _reportFuture = Future.value({'data': []});
        }
        break;
    }
    setState(() {});
  }

  /// Позволяет получить текущие записи отчёта вне этого виджета (через GlobalKey).
  List<ReportEntry> getCurrentData() => _currentData;

  /// Позволяет получить полный ответ с бэкенда (для PDF-заголовков и т.д.).
  Map<String, dynamic>? getCurrentResponse() => _currentResponse;

  /// Возвращает тип отчёта.
  ReportType get reportType => widget.reportType;

  /// Диалог выбора диапазона дат (только для интервала).
  Future<void> _pickDateInterval() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  /// Формируем заголовок для таблицы, используя общую функцию buildReceiveReportTitle.
  String _getHeaderText(Map<String, dynamic> response) {
    return buildReceiveReportTitle(widget.reportType, response);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final double fontSize = isWeb ? 24.0 : 12.0;
    final double headerFontSize = isWeb ? 30.0 : 16.0;
    final double headerTableRowFontSize = isWeb ? 24.0 : 14.0;
    final double columnSpacing = isWeb ? 34.0 : 16.0;
    final double horizontalMargin = isWeb ? 36.0 : 4.0;
    final double headerPadding = isWeb ? 36.0 : 8.0;

    return FutureBuilder<Map<String, dynamic>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        } else if (!snapshot.hasData ||
            (snapshot.data!['data'] is List && snapshot.data!['data'].isEmpty)) {
          return const Center(child: Text('Нет данных'));
        }

        final response = snapshot.data!;
        _currentResponse = response;
        final headerText = _getHeaderText(response);

        // Список записей (ReportEntry) в поле 'data'
        final List<ReportEntry> reportEntries = response['data'];
        _currentData = reportEntries;

        // Сама таблица, обёрнутая в ConstrainedBox с minWidth
        Widget table = Padding(
          padding: EdgeInsets.all(isWeb ? 16.0 : 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 390),
              child: DataTable(
                columnSpacing: columnSpacing,
                horizontalMargin: horizontalMargin,
                columns: [
                  DataColumn(
                    label: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Продукция',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: headerTableRowFontSize,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Ячейка',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: headerTableRowFontSize,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Всего',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: headerTableRowFontSize,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Дата приемки',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: headerTableRowFontSize,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: reportEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                          (states) => index % 2 == 0 ? Colors.grey.shade200 : Colors.white,
                    ),
                    cells: [
                      DataCell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.productName,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataCell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.cellName,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataCell(
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            item.quantity.toString(),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      DataCell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(item.recordDate),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );

        // Для "интервального" отчета добавляем выбор дат снизу
        if (widget.reportType == ReportType.interval) {
          return Column(
            children: [
              const Divider(height: 1, color: Colors.black),
              Padding(
                padding: EdgeInsets.all(headerPadding),
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.black),
              Expanded(child: table),
              Padding(
                padding: EdgeInsets.all(headerPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (_startDate != null && _endDate != null)
                            ? 'Интервал: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'
                            ' - ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                            : 'Интервал не выбран',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickDateInterval,
                      child: Text(
                        'Выбрать интервал',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Для дня/недели/месяца просто заголовок + таблица
          return Column(
            children: [
              const Divider(height: 1, color: Colors.black),
              Padding(
                padding: EdgeInsets.all(headerPadding),
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.black),
              Expanded(child: table),
            ],
          );
        }
      },
    );
  }
}
