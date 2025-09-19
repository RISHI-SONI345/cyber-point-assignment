import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
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
  final _scroll = ScrollController();
  late final Debouncer _debouncer;
  TextEditingController? _searchCtl;

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
    _searchCtl?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      debugPrint('[Scroll] No clients attached to controller yet');
      return;
    }

    final prov = context.read<FutureProductsProvider?>();
    if (_modeIndex != 0) {
      debugPrint('[Scroll] Ignored because current mode is Stream');
      return;
    }
    if (prov == null) {
      debugPrint('[Scroll] Provider is null');
      return;
    }
    if (prov.loadingMore) {
      debugPrint('[Scroll] Already loading more, skipping');
      return;
    }

    debugPrint(
      '[Scroll] extentAfter=${_scroll.position.extentAfter}, pixels=${_scroll.position.pixels}, max=${_scroll.position.maxScrollExtent}',
    );

    if (_scroll.position.extentAfter < 300) {
      debugPrint('[Scroll] Triggering loadMore()');
      prov.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ProductsRepository(ProductsApi())),
        ChangeNotifierProvider(
          create:
              (ctx) =>
                  FutureProductsProvider(ctx.read<ProductsRepository>())
                    ..loadFirstPage(),
        ),
      ],
      child: Scaffold(
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
              onSelectionChanged: (s) => setState(() => _modeIndex = s.first),
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
                      // handled in Commit 4 (stream)
                    }
                  });
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _modeIndex == 0
                      ? _FutureListView(
                        scrollController: _scroll,
                      ) // <-- pass it
                      : const Center(
                        child: Text('Stream tab (to be implemented)'),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // This context is BELOW MultiProvider, so Provider is visible here.
    final prov = context.read<FutureProductsProvider>();

    // Guard + reliable bottom detection
    if (!widget.scrollController.hasClients || prov.loadingMore) return;
    final remaining = widget.scrollController.position.extentAfter;
    // Debug
    debugPrint('[ChildScroll] extentAfter=$remaining; hasMore=${prov.hasMore}');
    if (remaining < 300) {
      debugPrint('[ChildScroll] Triggering loadMore()');
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
      onRefresh: () {
        debugPrint('[UI] Pull-to-refresh');
        return prov.refreshAll();
      },
      child: ListView.separated(
        controller: widget.scrollController,
        physics:
            const AlwaysScrollableScrollPhysics(), // helps with short lists
        itemCount: items.length + (prov.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i >= items.length) {
            debugPrint('[UI] Footer loader visible');
            return const FooterLoader();
          }
          final p = items[i];
          debugPrint('[UI] Render ${p.id} - ${p.title}');
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
