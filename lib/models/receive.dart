import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';

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
  /// Параметры [product] и [cell] должны быть получены отдельно.
  factory Receive.fromJson(Map<String, dynamic> json,
      {required Product product, required Cell cell}) {
    return Receive(
      receiveID: json['ReceiveID'] ?? 0,
      product: product,
      cell: cell,
      receiveQuantity: json['ReceiveQuantity'] ?? 0,
      receiveDate:
      DateTime.tryParse(json['ReceiveDate'] ?? '') ?? DateTime.now(),
    );
  }

  /// Преобразует объект Receive в JSON для отправки на сервер.
  /// Здесь receiveDate форматируется в строку формата "YYYY-MM-DD HH:MM:SS",
  Map<String, dynamic> toJson() {
    final formattedDate = "${receiveDate.year.toString().padLeft(4, '0')}-"
        "${receiveDate.month.toString().padLeft(2, '0')}-"
        "${receiveDate.day.toString().padLeft(2, '0')} "
        "${receiveDate.hour.toString().padLeft(2, '0')}:"
        "${receiveDate.minute.toString().padLeft(2, '0')}:"
        "${receiveDate.second.toString().padLeft(2, '0')}";

    return {
      'productID': product.productID,
      'cellID': cell.cellID,
      'receiveQuantity': receiveQuantity,
      'receiveDate': formattedDate,
    };
  }
}
