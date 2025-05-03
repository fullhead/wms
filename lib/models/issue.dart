import 'package:wms/core/utils.dart';
import 'package:wms/models/category.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';

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

  /// Используется, если продукт и ячейка уже загружены отдельно.
  factory Issue.fromJson(
      Map<String, dynamic> json, {
        required Product product,
        required Cell cell,
      }) {
    return Issue(
      issueID:       json['IssueID'] ?? 0,
      product:       product,
      cell:          cell,
      issueQuantity: json['IssueQuantity'] ?? 0,
      issueDate:     DateTime.tryParse(json['IssueDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// API вернул всё одним объектом (`withDetails=true`).
  factory Issue.fromJsonWithDetails(Map<String, dynamic> json) {
    final category = Category(
      categoryID  : json['CategoryID']  ?? 0,
      categoryName: json['categoryName'] ?? json['CategoryName'] ?? '',
    );

    final product = Product(
      productID      : json['ProductID']      ?? 0,
      productCategory: category,
      productName    : json['productName']    ?? json['ProductName'] ?? '',
      productImage   : json['productImage']   ?? json['ProductImage'] ?? '',
      productBarcode : json['productBarcode'] ?? json['ProductBarcode'] ?? '',
    );

    final cell = Cell(
      cellID  : json['CellID']  ?? 0,
      cellName: json['cellName'] ?? json['CellName'] ?? '',
    );

    return Issue(
      issueID      : json['IssueID'] ?? 0,
      product      : product,
      cell         : cell,
      issueQuantity: json['IssueQuantity'] ?? 0,
      issueDate    : DateTime.tryParse(json['IssueDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// Конструктор для создания новой записи выдачи.
  Map<String, dynamic> toJson() {
    final dt =
        '${issueDate.year}-${twoDigits(issueDate.month)}-${twoDigits(issueDate.day)} '
        '${twoDigits(issueDate.hour)}:${twoDigits(issueDate.minute)}:${twoDigits(issueDate.second)}';

    return {
      'productID'    : product.productID,
      'cellID'       : cell.cellID,
      'issueQuantity': issueQuantity,
      'issueDate'    : dt,
    };
  }
}
