import 'dart:async';
import '../models/product.dart';
import '../services/products_repo.dart';

/// State object for our Stream-based list.
/// Holds the current items, flags for loading, and any error.
class StreamProductsState {
  const StreamProductsState({
    this.loading = false,
    this.items = const [],
    this.error,
    this.hasMore = true,
    this.loadingMore = false,
    this.searchQuery = '',
  });

  final bool loading;
  final List<Product> items;
  final String? error;
  final bool hasMore;
  final bool loadingMore;
  final String searchQuery;

  List<Product> get filteredItems {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  StreamProductsState copyWith({
    bool? loading,
    List<Product>? items,
    String? error,
    bool? hasMore,
    bool? loadingMore,
    String? searchQuery,
  }) {
    return StreamProductsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Controller that manages the product list as a stream.
/// Similar to the Future provider but pushes updates through StreamController.
class StreamProductsController {
  StreamProductsController(this._repo);

  final ProductsRepository _repo;
  final _controller = StreamController<StreamProductsState>.broadcast();

  Stream<StreamProductsState> get stream => _controller.stream;

  StreamProductsState _state = const StreamProductsState();
  bool _busy = false;

  void _emit(StreamProductsState s) {
    _state = s;
    _controller.add(s);
  }

  Future<void> loadFirstPage() async {
    if (_busy) return;
    _busy = true;
    _emit(const StreamProductsState(loading: true));
    try {
      final page = await _repo.getPage(skip: 0);
      _emit(
        _state.copyWith(
          loading: false,
          items: page,
          hasMore: page.length == 10,
          error: null,
        ),
      );
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: e.toString()));
    } finally {
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    if (_busy || !_state.hasMore || _state.loading) return;
    _busy = true;
    _emit(_state.copyWith(loadingMore: true));
    try {
      final next = await _repo.getPage(skip: _state.items.length);
      final merged = [..._state.items, ...next];
      _emit(
        _state.copyWith(
          items: merged,
          hasMore: next.length == 10,
          loadingMore: false,
        ),
      );
    } catch (e) {
      _emit(_state.copyWith(loadingMore: false, error: e.toString()));
    } finally {
      _busy = false;
    }
  }

  Future<void> refreshAll() => loadFirstPage();

  void setSearchQuery(String q) {
    _emit(_state.copyWith(searchQuery: q));
  }

  void dispose() {
    _controller.close();
  }
}
