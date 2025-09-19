import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/products_repo.dart';

class FutureProductsProvider extends ChangeNotifier {
  FutureProductsProvider(this._repo);

  final ProductsRepository _repo;

  final List<Product> _items = <Product>[];
  List<Product> get items => List.unmodifiable(
    _searchQuery.isEmpty
        ? _items
        : _items
            .where(
              (p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList(),
  );

  bool _initialLoading = false;
  bool get initialLoading => _initialLoading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> loadFirstPage() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _error = null;
    _items.clear();
    _hasMore = true;
    notifyListeners();
    try {
      final page = await _repo.getPage(skip: 0);
      _items.addAll(page);
      _hasMore = page.length == 10;
    } catch (e) {
      _error = e.toString();
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    debugPrint('[Provider] loadMore called');
    if (_loadingMore || !_hasMore || _initialLoading) {
      debugPrint(
        '[Provider] loadMore skipped: '
        'loadingMore=$_loadingMore, hasMore=$_hasMore, initialLoading=$_initialLoading',
      );
      return;
    }

    _loadingMore = true;
    notifyListeners();
    debugPrint('[Provider] Requesting page starting at skip=${_items.length}');

    try {
      final page = await _repo.getPage(skip: _items.length);
      debugPrint('[Provider] Received ${page.length} items');
      _items.addAll(page);
      _hasMore = page.length == 10;
      debugPrint(
        '[Provider] New items total=${_items.length}, hasMore=$_hasMore',
      );
    } catch (e) {
      debugPrint('[Provider] Error during loadMore: $e');
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    // Pull-to-refresh resets to first page
    await loadFirstPage();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
