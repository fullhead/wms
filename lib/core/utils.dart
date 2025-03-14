/// Класс собственного исключения.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Вспомогательная функция для форматирования чисел с двумя знаками.
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Универсальная функция для парсинга статуса.
bool parseStatus(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  return false;
}

/// Функция для форматирования даты и времени.
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

/// Функция для форматирования даты.
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
}

/// Функция для форматирования времени.
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
