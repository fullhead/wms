class Category {
  int categoryID;
  String categoryName;

  Category({
    required this.categoryID,
    required this.categoryName,
  });

  /// Фабричный конструктор для создания категории из JSON (Map) полученного от API.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryID: json['CategoryID'] ?? 0,
      categoryName: json['CategoryName'] ?? '',
    );
  }

  /// Преобразует объект Category в Map (JSON) для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
    };
  }
}
