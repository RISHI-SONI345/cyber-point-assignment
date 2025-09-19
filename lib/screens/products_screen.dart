import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _modeIndex = 0; // 0 = Future, 1 = Stream (wired in later)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products Explorer')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Future')),
              ButtonSegment(value: 1, label: Text('Stream')),
            ],
            selected: {_modeIndex},
            onSelectionChanged: (s) => setState(() => _modeIndex = s.first),
          ),
          const Divider(height: 1),
          const Expanded(child: Center(child: Text('Helllo there'))),
        ],
      ),
    );
  }
}
