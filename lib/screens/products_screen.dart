import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../providers/products_stream.dart';
import '../services/products_api.dart';
import '../services/products_repo.dart';
import '../utils/debouncer.dart';
import '../widgets/about_screen.dart';
import '../widgets/product_row.dart';
import '../widgets/states.dart';
import 'product_detail.dart';

/// Top-level screen with two modes:
///  - Future-based pagination
///  - Stream-based pagination
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // 0 = Future tab, 1 = Stream tab
  int _modeIndex = 0;

  // One controller reused across tabs.
  final ScrollController _scroll = ScrollController();

  // Debounced search to avoid spamming the data layer.
  late final Debouncer _debouncer;
  late final TextEditingController _searchCtl;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(const Duration(milliseconds: 350));
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _debouncer.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide repository + controllers once; children attach their own listeners.
    return MultiProvider(
      providers: [
        Provider<ProductsRepository>(
          create: (_) => ProductsRepository(ProductsApi()),
        ),
        ChangeNotifierProvider<FutureProductsProvider>(
          create:
              (ctx) =>
                  FutureProductsProvider(ctx.read<ProductsRepository>())
                    ..loadFirstPage(),
        ),
        Provider<StreamProductsController>(
          create:
              (ctx) =>
                  StreamProductsController(ctx.read<ProductsRepository>())
                    ..loadFirstPage(),
          dispose: (_, ctrl) => ctrl.dispose(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Products Explorer'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Future')),
                    ButtonSegment(value: 1, label: Text('Stream')),
                  ],
                  selected: {_modeIndex},
                  onSelectionChanged: (s) {
                    setState(() => _modeIndex = s.first);
                    // Optional: “nudge” the scroll so we don’t immediately think we’re at bottom.
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(
                        _scroll.position.pixels.clamp(
                          0,
                          _scroll.position.maxScrollExtent,
                        ),
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: _searchCtl,
                    decoration: const InputDecoration(
                      hintText: 'Search by title…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (txt) {
                      _debouncer.run(() {
                        if (_modeIndex == 0) {
                          context.read<FutureProductsProvider>().setSearchQuery(
                            txt,
                          );
                        } else {
                          context
                              .read<StreamProductsController>()
                              .setSearchQuery(txt);
                        }
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child:
                      _modeIndex == 0
                          ? _FutureListView(scrollController: _scroll)
                          : _StreamListView(scrollController: _scroll),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------------------------- FUTURE TAB LIST ---------------------------- */

class _FutureListView extends StatefulWidget {
  const _FutureListView({required this.scrollController});
  final ScrollController scrollController;

  @override
  State<_FutureListView> createState() => _FutureListViewState();
}

class _FutureListViewState extends State<_FutureListView> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onChildScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onChildScroll);
    super.dispose();
  }

  void _onChildScroll() {
    final prov = context.read<FutureProductsProvider>();
    if (!widget.scrollController.hasClients) return;

    // Hard guards: do nothing if busy or no more pages.
    if (prov.loadingMore || !prov.hasMore) return;

    final remaining = widget.scrollController.position.extentAfter;
    if (remaining < 300) {
      prov.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FutureProductsProvider>();

    if (prov.initialLoading) return const FullScreenLoader();
    if (prov.error != null && prov.items.isEmpty) {
      return FullScreenError(message: prov.error!, onRetry: prov.loadFirstPage);
    }
    if (prov.items.isEmpty) {
      // Don’t attach controller here—prevents accidental load loops on short lists.
      return RefreshIndicator(
        onRefresh: prov.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 300),
            FullScreenEmpty(message: 'No products found.'),
          ],
        ),
      );
    }

    final items = prov.items;
    return RefreshIndicator(
      onRefresh: prov.refreshAll,
      child: ListView.separated(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (prov.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i >= items.length) return const FooterLoader();
          final p = items[i];
          return ProductRow(
            product: p,
            onTap:
                () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p),
                  ),
                ),
          );
        },
      ),
    );
  }
}

/* ---------------------------- STREAM TAB LIST ---------------------------- */

class _StreamListView extends StatefulWidget {
  const _StreamListView({required this.scrollController});
  final ScrollController scrollController;

  @override
  State<_StreamListView> createState() => _StreamListViewState();
}

class _StreamListViewState extends State<_StreamListView> {
  late final StreamProductsController _ctrl;
  StreamProductsState? _lastState; // so the scroll listener can consult it

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<StreamProductsController>();
    widget.scrollController.addListener(_onChildScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onChildScroll);
    super.dispose();
  }

  void _onChildScroll() {
    if (!widget.scrollController.hasClients) return;
    final s = _lastState;
    if (s == null) return;

    // CRITICAL GUARDS: don’t paginate while busy, with empty items, or when no more pages.
    if (s.loading || s.loadingMore || !s.hasMore || s.items.isEmpty) return;

    final remaining = widget.scrollController.position.extentAfter;
    if (remaining < 300) {
      _ctrl.loadMore(); // internal guards + tiny cooldown in controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StreamProductsState>(
      stream: _ctrl.stream,
      initialData: const StreamProductsState(loading: true),
      builder: (context, snap) {
        final s = snap.data ?? const StreamProductsState(loading: true);
        _lastState = s;

        if (s.loading && s.items.isEmpty) return const FullScreenLoader();

        if (s.error != null && s.items.isEmpty) {
          return FullScreenError(
            message: s.error!,
            onRetry: _ctrl.loadFirstPage,
          );
        }

        final visible = s.filteredItems;
        if (visible.isEmpty) {
          // IMPORTANT: don’t attach the shared scroll controller to the empty view.
          return RefreshIndicator(
            onRefresh: _ctrl.refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                FullScreenEmpty(message: 'No products found.'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _ctrl.refreshAll,
          child: ListView.separated(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: visible.length + (s.loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              if (i >= visible.length) return const FooterLoader();
              final p = visible[i];
              return ProductRow(
                product: p,
                onTap:
                    () => Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
              );
            },
          ),
        );
      },
    );
  }
}
