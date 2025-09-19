import '../models/product.dart';
import 'products_api.dart';

class ProductsRepository {
  ProductsRepository(this._api);
  final ProductsApi _api;

  Future<List<Product>> getPage({int limit = 10, required int skip}) {
    return _api.fetchPage(limit: limit, skip: skip);
  }
}
