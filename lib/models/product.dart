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

  /// Когда категорию получили отдельным запросом.
  factory Product.fromJson(Map<String, dynamic> json, Category category) =>
      Product(
        productID: json['ProductID'] ?? json['productID'] ?? 0,
        productCategory: category,
        productName: json['ProductName'] ?? json['productName'] ?? '',
        productImage: json['ProductImage'] ?? json['productImage'] ?? '',
        productBarcode: json['ProductBarcode'] ?? json['productBarcode'] ?? '',
      );

  /// Когда бэк вернул продукты сразу с категорией (`?withCategory=true`).
  factory Product.fromJsonWithCategory(Map<String, dynamic> json) =>
      Product(
        productID: json['ProductID'] ?? json['productID'] ?? 0,
        productCategory: Category.fromJson(json),
        productName: json['ProductName'] ?? json['productName'] ?? '',
        productImage: json['ProductImage'] ?? json['productImage'] ?? '',
        productBarcode: json['ProductBarcode'] ?? json['productBarcode'] ?? '',
      );

  /// JSON для POST/PUT на сервер.
  Map<String, dynamic> toJson() => {
    'categoryID': productCategory.categoryID,
    'productName': productName,
    'productImage': productImage,
    'productBarcode': productBarcode,
  };
}
