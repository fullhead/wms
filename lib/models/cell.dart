class Cell {
  int cellID;
  String cellName;

  Cell({
    required this.cellID,
    required this.cellName,
  });

  /// Фабричный конструктор для создания ячейки из JSON (Map) полученного от API.
  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      cellID: json['CellID'] ?? 0,
      cellName: json['CellName'] ?? '',
    );
  }

  /// Преобразует объект Cell в Map (JSON) для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'cellName': cellName,
    };
  }
}
