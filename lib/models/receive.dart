import 'package:wms/core/utils.dart';
import 'package:wms/models/category.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';

/// Модель записи приёмки.
class Receive {
  int receiveID;
  Product product;
  Cell cell;
  int receiveQuantity;
  DateTime receiveDate;

  Receive({
    required this.receiveID,
    required this.product,
    required this.cell,
    required this.receiveQuantity,
    required this.receiveDate,
  });

  /// Когда продукт/ячейка загружаются отдельно.
  factory Receive.fromJson(
    Map<String, dynamic> json, {
    required Product product,
    required Cell cell,
  }) {
    return Receive(
      receiveID: json['ReceiveID'] ?? 0,
      product: product,
      cell: cell,
      receiveQuantity: json['ReceiveQuantity'] ?? 0,
      receiveDate:
          DateTime.tryParse(json['ReceiveDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// API вернул всё одной строкой.
  factory Receive.fromJsonWithDetails(Map<String, dynamic> json) {
    /* Категория */
    final category = Category(
      categoryID: json['CategoryID'] ?? 0,
      categoryName: json['categoryName'] ?? json['CategoryName'] ?? '',
    );

    /* Продукт */
    final product = Product(
      productID: json['ProductID'] ?? 0,
      productCategory: category,
      productName: json['productName'] ?? json['ProductName'] ?? '',
      productImage: json['productImage'] ?? json['ProductImage'] ?? '',
      productBarcode: json['productBarcode'] ?? json['ProductBarcode'] ?? '',
    );

    /* Ячейка */
    final cell = Cell(
      cellID: json['CellID'] ?? 0,
      cellName: json['cellName'] ?? json['CellName'] ?? '',
    );

    return Receive(
      receiveID: json['ReceiveID'] ?? 0,
      product: product,
      cell: cell,
      receiveQuantity: json['ReceiveQuantity'] ?? 0,
      receiveDate:
          DateTime.tryParse(json['ReceiveDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// Конструктор для создания новой записи приёмки.
  Map<String, dynamic> toJson() {
    final dt =
        '${receiveDate.year}-${twoDigits(receiveDate.month)}-${twoDigits(receiveDate.day)} '
        '${twoDigits(receiveDate.hour)}:${twoDigits(receiveDate.minute)}:${twoDigits(receiveDate.second)}';

    return {
      'productID': product.productID,
      'cellID': cell.cellID,
      'receiveQuantity': receiveQuantity,
      'receiveDate': dt,
    };
  }
}
