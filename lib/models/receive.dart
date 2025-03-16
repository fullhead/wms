import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/core/utils.dart';

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

  /// Фабричный конструктор для создания объекта Receive из JSON, полученного от API.
  factory Receive.fromJson(Map<String, dynamic> json, {required Product product, required Cell cell}) {
    return Receive(
      receiveID: json['ReceiveID'] ?? 0,
      product: product,
      cell: cell,
      receiveQuantity: json['ReceiveQuantity'] ?? 0,
      receiveDate: DateTime.tryParse(json['ReceiveDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// Преобразует объект Receive в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    final formattedDate =
        '${receiveDate.year}-${twoDigits(receiveDate.month)}-${twoDigits(receiveDate.day)} '
        '${twoDigits(receiveDate.hour)}:${twoDigits(receiveDate.minute)}:${twoDigits(receiveDate.second)}';
    return {
      'productID': product.productID,
      'cellID': cell.cellID,
      'receiveQuantity': receiveQuantity,
      'receiveDate': formattedDate,
    };
  }
}
