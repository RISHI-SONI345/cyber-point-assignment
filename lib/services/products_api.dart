import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsApi {
  ProductsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _base = 'https://dummyjson.com';

  Future<List<Product>> fetchPage({int limit = 10, required int skip}) async {
    final uri = Uri.parse('$_base/products?limit=$limit&skip=$skip');
    debugPrint('[API] Fetching $uri');
    final res = await _client.get(uri);
    debugPrint('[API] Status code: ${res.statusCode}');
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (map['products'] as List).length;
    debugPrint('[API] Response contains $products products');
    return (map['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  void close() {
    _client.close();
  }
}
