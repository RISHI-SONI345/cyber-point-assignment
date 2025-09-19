import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../providers/products_stream.dart'; // <-- add (Commit 4)
import '../services/products_api.dart';
import '../services/products_repo.dart';
import '../utils/debouncer.dart';
import '../widgets/product_row.dart';
import '../widgets/states.dart';
import 'product_detail.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _modeIndex = 0; // 0 = Future, 1 = Stream
  final ScrollController _scroll = ScrollController();
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
    // Provide repository + controllers once; children attach their own scroll listeners
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
            appBar: AppBar(title: const Text('Products Explorer')),
            body: Column(
              children: [
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Future')),
                    ButtonSegment(value: 1, label: Text('Stream')),
                  ],
                  selected: {_modeIndex},
                  onSelectionChanged:
                      (s) => setState(() => _modeIndex = s.first),
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
    // Provider is visible here (child context under MultiProvider)
    final prov = context.read<FutureProductsProvider>();

    if (!widget.scrollController.hasClients || prov.loadingMore) return;

    final remaining = widget.scrollController.position.extentAfter;
    // Debug
    // debugPrint('[FutureScroll] extentAfter=$remaining; hasMore=${prov.hasMore}');
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
      return const FullScreenEmpty(message: 'No products found.');
    }

    final items = prov.items;
    return RefreshIndicator(
      onRefresh: prov.refreshAll,
      child: ListView.separated(
        controller: widget.scrollController,
        physics:
            const AlwaysScrollableScrollPhysics(), // works even if list is short
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
    final remaining = widget.scrollController.position.extentAfter;
    if (remaining < 300) {
      _ctrl.loadMore(); // guarded inside controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StreamProductsState>(
      stream: _ctrl.stream,
      builder: (context, snap) {
        final s = snap.data ?? const StreamProductsState(loading: true);

        if (s.loading && s.items.isEmpty) return const FullScreenLoader();
        if (s.error != null && s.items.isEmpty) {
          return FullScreenError(
            message: s.error!,
            onRetry: _ctrl.loadFirstPage,
          );
        }

        final visible = s.filteredItems;
        if (visible.isEmpty) {
          return RefreshIndicator(
            onRefresh: _ctrl.refreshAll,
            child: ListView(
              controller: widget.scrollController,
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
