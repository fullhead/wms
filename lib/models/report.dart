class ReportEntry {
  final String productName;
  final String cellName;
  final int quantity;
  final DateTime recordDate;
  final DateTime reportDate;

  ReportEntry({
    required this.productName,
    required this.cellName,
    required this.quantity,
    required this.recordDate,
    required this.reportDate,
  });

  /// Фабричный конструктор для создания объекта ReportEntry из JSON.
  factory ReportEntry.fromJson(Map<String, dynamic> json) {
    return ReportEntry(
      productName: json['ProductName'] ?? '',
      cellName: json['CellName'] ?? '',
      quantity: json['quantity'] ?? 0,
      recordDate: DateTime.tryParse(json['recordDate']?.toString() ?? '') ?? DateTime.now(),
      reportDate: DateTime.tryParse(json['ReportDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
