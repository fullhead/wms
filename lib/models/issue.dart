import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/core/utils.dart';

/// Модель записи выдачи.
class Issue {
  int issueID;
  Product product;
  Cell cell;
  int issueQuantity;
  DateTime issueDate;

  Issue({
    required this.issueID,
    required this.product,
    required this.cell,
    required this.issueQuantity,
    required this.issueDate,
  });

  /// Фабричный конструктор для создания объекта Issue из JSON, полученного от API.
  factory Issue.fromJson(Map<String, dynamic> json, {required Product product, required Cell cell}) {
    return Issue(
      issueID: json['IssueID'] ?? 0,
      product: product,
      cell: cell,
      issueQuantity: json['IssueQuantity'] ?? 0,
      issueDate: DateTime.tryParse(json['IssueDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// Преобразует объект Issue в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    final formattedDate =
        '${issueDate.year}-${twoDigits(issueDate.month)}-${twoDigits(issueDate.day)} '
        '${twoDigits(issueDate.hour)}:${twoDigits(issueDate.minute)}:${twoDigits(issueDate.second)}';
    return {
      'productID': product.productID,
      'cellID': cell.cellID,
      'issueQuantity': issueQuantity,
      'issueDate': formattedDate,
    };
  }
}
