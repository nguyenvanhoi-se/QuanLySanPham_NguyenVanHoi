import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class Product {
  const Product(this.id, this.name, this.price, this.quantity, this.image);
  final String id, name, image;
  final int price, quantity;
  factory Product.fromJson(Map<String, dynamic> row) => Product(
    row['_id'] as String,
    row['name'] as String,
    row['price'] as int,
    row['soluong'] as int,
    row['image'] as String,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'soluong': quantity,
    'image': image,
  };
}

class ProductApi {
  static String get base {
    const configured = String.fromEnvironment('API_URL');
    if (configured.isNotEmpty) return configured;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final host = isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:3000/api/products';
  }

  static final session = ValueNotifier<String?>(null);
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (session.value != null) 'Authorization': 'Bearer ${session.value}',
  };

  static Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(base).resolve('auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    session.value = decode(response)['token'] as String;
  }

  static Future<void> logout() async {
    final response = await http.post(
      Uri.parse(base).resolve('auth/logout'),
      headers: headers,
    );
    if (response.statusCode != 401) decode(response);
    session.value = null;
  }

  static dynamic decode(http.Response response) {
    if (response.statusCode == 401) session.value = null;
    if (response.statusCode == 413) {
      throw Exception('Ảnh quá lớn. Hãy chọn ảnh nhỏ hơn.');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) throw Exception(body['message']);
    return body;
  }

  static Future<List<Product>> list(String keyword) async {
    final uri = Uri.parse(base)
        .replace(queryParameters: {'search': keyword.trim()});
    final rows = decode(await http.get(uri, headers: headers)) as List;
    return rows
        .map((row) => Product.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(Product p) async {
    final body = jsonEncode(p.toJson());
    final response = p.id.isEmpty
        ? await http.post(Uri.parse(base), headers: headers, body: body)
        : await http.put(
            Uri.parse('$base/${p.id}'),
            headers: headers,
            body: body,
          );
    decode(response);
  }

  static Future<void> remove(String id) async {
    decode(await http.delete(Uri.parse('$base/$id'), headers: headers));
  }
}
