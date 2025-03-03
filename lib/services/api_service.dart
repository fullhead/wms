import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/group.dart';
import 'package:wms/models/category.dart' as wms_category;

class APIService {
  /// Базовый URL серверного API.
  final String baseUrl;

  APIService({required this.baseUrl});

  /// Возвращает заголовки для запросов.
  /// Если [auth] == true, то добавляется токен авторизации.
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---------------------------
  // Методы для работы с группами
  // ---------------------------

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/groups'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllGroups: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllGroups error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении групп');
    }
  }

  Future<Group> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/groups/$groupId'), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('getGroupById ($groupId): ${response.body}');
      return Group.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getGroupById error ($groupId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении группы по ID');
    }
  }

  /// Создание группы (ID не передаём, бэкенд генерирует его сам).
  Future<void> createGroup(Map<String, dynamic> groupMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createGroup payload: ${jsonEncode(groupMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 201) {
      debugPrint('createGroup: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createGroup error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании группы');
    }
  }

  /// Обновление группы: ID не берём из JSON, а передаём отдельным параметром.
  Future<void> updateGroup(Map<String, dynamic> groupMap, int groupId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateGroup payload for groupId $groupId: ${jsonEncode(groupMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/groups/$groupId'),
      headers: headers,
      body: jsonEncode(groupMap),
    );

    if (response.statusCode == 200) {
      debugPrint('updateGroup ($groupId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateGroup error ($groupId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении группы');
    }
  }

  Future<void> deleteGroup(int groupID) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupID'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      debugPrint('deleteGroup ($groupID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteGroup error ($groupID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении группы');
    }
  }

  // ------------------------------
  // Методы для работы с пользователями
  // ------------------------------

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllUsers: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllUsers error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении пользователей');
    }
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('getUserById ($userId): ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getUserById error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении пользователя');
    }
  }

  Future<void> createUser(Map<String, dynamic> userMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createUser payload: ${jsonEncode(userMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    if (response.statusCode == 201) {
      debugPrint('createUser: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании пользователя');
    }
  }

  Future<void> updateUser(Map<String, dynamic> userMap, int userId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateUser payload for userId $userId: ${jsonEncode(userMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(userMap),
    );
    if (response.statusCode == 200) {
      debugPrint('updateUser ($userId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateUser error ($userId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении пользователя');
    }
  }

  Future<void> deleteUser(int userID) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userID'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('deleteUser ($userID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteUser error ($userID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении пользователя');
    }
  }

  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: await _getHeaders(auth: false),
      body: jsonEncode(credentials),
    );
    if (response.statusCode == 200) {
      debugPrint('loginUser: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('loginUser error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка авторизации');
    }
  }

  // ---------------------------
  // Методы для работы с категориями
  // ---------------------------

  Future<List<Map<String, dynamic>>> getAllCategory() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllCategory: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllCategory error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категорий');
    }
  }

  Future<wms_category.Category> getCategoryById(int categoryId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId'), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return wms_category.Category.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getCategoryById error ($categoryId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении категории по ID');
    }
  }

  Future<void> createCategory(Map<String, dynamic> categoryMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createCategory payload: ${jsonEncode(categoryMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: jsonEncode(categoryMap),
    );

    if (response.statusCode == 201) {
      debugPrint('createCategory: ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createCategory error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании категории');
    }
  }

  Future<void> updateCategory(Map<String, dynamic> categoryMap, int categoryId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateCategory payload for categoryId $categoryId: ${jsonEncode(categoryMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: headers,
      body: jsonEncode(categoryMap),
    );

    if (response.statusCode == 200) {
      debugPrint('updateCategory ($categoryId): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateCategory error ($categoryId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении категории');
    }
  }

  Future<void> deleteCategory(int categoryID) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/categories/$categoryID'), headers: headers);
    if (response.statusCode == 200) {
      debugPrint('deleteCategory ($categoryID): ${response.body}');
      return;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteCategory error ($categoryID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении категории');
    }
  }

  // ---------------------------
  // Методы для работы с продукцией
  // ---------------------------

  Future<List<Map<String, dynamic>>> getAllProduct() async {
    final headers = await _getHeaders();
    final response =
    await http.get(Uri.parse('$baseUrl/products'), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      debugPrint('getAllProduct: ${response.body}');
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getAllProduct error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении продукции');
    }
  }

  Future<Map<String, dynamic>> getProductById(int productId) async {
    final headers = await _getHeaders();
    final response =
    await http.get(Uri.parse('$baseUrl/products/$productId'),
        headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('getProductById ($productId): ${response.body}');
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('getProductById error ($productId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при получении продукции по ID');
    }
  }

  Future<String> createProduct(Map<String, dynamic> productMap) async {
    final headers = await _getHeaders();
    debugPrint('Sending createProduct payload: ${jsonEncode(productMap)}');
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: headers,
      body: jsonEncode(productMap),
    );

    if (response.statusCode == 201) {
      debugPrint('createProduct: ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция создана';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('createProduct error: ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при создании продукции');
    }
  }

  Future<String> updateProduct(Map<String, dynamic> productMap, int productId) async {
    final headers = await _getHeaders();
    debugPrint('Sending updateProduct payload for productId $productId: ${jsonEncode(productMap)}');
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
      body: jsonEncode(productMap),
    );

    if (response.statusCode == 200) {
      debugPrint('updateProduct ($productId): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция обновлена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('updateProduct error ($productId): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при обновлении продукции');
    }
  }

  Future<String> deleteProduct(int productID) async {
    final headers = await _getHeaders();
    final response = await http.delete(
        Uri.parse('$baseUrl/products/$productID'),
        headers: headers);
    if (response.statusCode == 200) {
      debugPrint('deleteProduct ($productID): ${response.body}');
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Продукция удалена';
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('deleteProduct error ($productID): ${response.body}');
      throw ApiException(errorData['error'] ?? 'Неизвестная ошибка при удалении продукции');
    }
  }

  Future<String> uploadProductImage(String imagePath) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/products/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    // Поле 'image' должно совпадать с именем, ожидаемым на сервере
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['path'];
    } else {
      final errorData = jsonDecode(response.body);
      throw ApiException(errorData['error'] ?? 'Ошибка при загрузке изображения');
    }
  }
}
