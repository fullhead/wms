import 'category.dart';

class Product {
  int productID;
  Category productCategory;
  String productName;
  String productImage;
  String productBarcode;

  Product({
    required this.productID,
    required this.productCategory,
    required this.productName,
    required this.productImage,
    required this.productBarcode,
  });

  /// Фабричный конструктор для создания объекта Product из JSON, полученного от API.
  factory Product.fromJson(Map<String, dynamic> json, Category category) {
    return Product(
      productID: json['ProductID'] ?? 0,
      productCategory: category,
      productName: json['ProductName'] ?? '',
      productImage: json['ProductImage'] ?? '',
      productBarcode: json['ProductBarcode'] ?? '',
    );
  }

  /// Преобразует объект Product в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'categoryID': productCategory.categoryID,
      'productName': productName,
      'productImage': productImage,
      'productBarcode': productBarcode,
    };
  }
}
