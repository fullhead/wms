import 'package:wms/views/report/report_type.dart';

/// Собственное исключение для обработки ошибок API.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Форматирует целое число так, чтобы всегда было минимум 2 знака (например, "07").
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Универсальная функция парсинга статуса (true/false).
bool parseStatus(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  return false;
}

/// Возвращает строку вида "YYYY-MM-DD HH:mm" (локальная дата/время).
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

/// Возвращает строку вида "YYYY-MM-DD" (локальная дата).
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
}

/// Возвращает строку вида "HH:mm" (локальное время).
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

/// Преобразует номер месяца (строка "01" - "12") в название на русском.
String getMonthName(String month) {
  switch (month) {
    case '01':
      return 'Январь';
    case '02':
      return 'Февраль';
    case '03':
      return 'Март';
    case '04':
      return 'Апрель';
    case '05':
      return 'Май';
    case '06':
      return 'Июнь';
    case '07':
      return 'Июль';
    case '08':
      return 'Август';
    case '09':
      return 'Сентябрь';
    case '10':
      return 'Октябрь';
    case '11':
      return 'Ноябрь';
    case '12':
      return 'Декабрь';
    default:
      return month;
  }
}

/// Формирует человекочитаемый заголовок (например, "Отчет за день 2025-03-15")
String buildReceiveReportTitle(ReportType reportType, Map<String, dynamic> response) {
  switch (reportType) {
    case ReportType.daily:
      final dateStr = response['date'] ?? '';
      return 'Отчет за день $dateStr';

    case ReportType.weekly:
      final weekStr = response['week'] ?? '';
      if (weekStr is String && weekStr.contains(' от ') && weekStr.contains(' до ')) {
        final parts = weekStr.split(' ');
        if (parts.length >= 5) {
          final start = parts[2].trim();
          final end = parts[4].trim();
          return 'Отчет за неделю от $start до $end';
        }
      }
      return 'Отчет за неделю';

    case ReportType.monthly:
      final year = response['year'] ?? '';
      final monthRaw = (response['month'] ?? '').toString();
      final monthName = getMonthName(monthRaw);
      return 'Отчет за месяц $year-$monthRaw ($monthName)';

    case ReportType.interval:
      final start = response['startDate'] ?? '';
      final end = response['endDate'] ?? '';
      return 'Отчет за интервал с $start по $end';
  }
}
