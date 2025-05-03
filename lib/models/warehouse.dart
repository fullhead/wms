import 'cell.dart';
import 'product.dart';
import 'category.dart';

/// Модель записи склада.
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

  /// Cell и Product приходят отдельно.
  factory Warehouse.fromJson(
      Map<String, dynamic> json,
      Cell cell,
      Product product,
      ) {
    return Warehouse(
      warehouseID: json['WarehouseID'] ?? 0,
      warehouseCellID: cell,
      warehouseProductID: product,
      warehouseQuantity: json['WarehouseQuantity'] ?? 0,
      warehouseUpdateDate: DateTime.tryParse(
          json['WarehouseUpdateDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Сервер уже отдаёт все детали (cellName, product*, categoryName).
  factory Warehouse.fromJsonWithDetails(Map<String, dynamic> json) {
    final category = Category(
      categoryID: 0, // ID по JOIN не отдаём, он тут не нужен
      categoryName: json['categoryName'] ?? '',
    );

    final product = Product(
      productID: json['ProductID'] ?? 0,
      productCategory: category,
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      productBarcode: json['productBarcode'] ?? '',
    );

    final cell = Cell(
      cellID: json['CellID'] ?? 0,
      cellName: json['cellName'] ?? '',
    );

    return Warehouse(
      warehouseID: json['WarehouseID'] ?? 0,
      warehouseCellID: cell,
      warehouseProductID: product,
      warehouseQuantity: json['WarehouseQuantity'] ?? 0,
      warehouseUpdateDate: DateTime.tryParse(
          json['WarehouseUpdateDate']?.toString() ?? '') ??
          DateTime.now(),
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
