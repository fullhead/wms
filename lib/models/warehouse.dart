import 'cell.dart';
import 'product.dart';

class Warehouse {
  final int warehouseID;
  final Cell warehouseCellID;
  final Product warehouseProductID;
  final int warehouseQuantity;
  final DateTime warehouseUpdateDate;

  Warehouse({
    required this.warehouseID,
    required this.warehouseCellID,
    required this.warehouseProductID,
    required this.warehouseQuantity,
    required this.warehouseUpdateDate,
  });

  /// Фабричный конструктор для создания объекта Warehouse из JSON.
  factory Warehouse.fromJson(Map<String, dynamic> json, Cell cell, Product product) {
    return Warehouse(
      warehouseID: json['WarehouseID'] ?? 0,
      warehouseCellID: cell,
      warehouseProductID: product,
      warehouseQuantity: json['WarehouseQuantity'] ?? 0,
      warehouseUpdateDate: DateTime.tryParse(json['WarehouseUpdateDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Преобразует объект Warehouse в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'warehouseQuantity': warehouseQuantity,
      'warehouseUpdateDate': warehouseUpdateDate.toIso8601String(),
      'cellID': warehouseCellID.cellID,
      'productID': warehouseProductID.productID,
    };
  }
}
