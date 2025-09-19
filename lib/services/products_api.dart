import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsApi {
  ProductsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _base = 'https://dummyjson.com';

  Future<List<Product>> fetchPage({int limit = 10, required int skip}) async {
    final uri = Uri.parse('$_base/products?limit=$limit&skip=$skip');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list =
        (map['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return list.map(Product.fromJson).toList(growable: false);
  }

  void close() {
    _client.close();
  }
}
