import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:products_explorer/widgets/product_row.dart';
import 'package:products_explorer/models/product.dart';

void main() {
  testWidgets('ProductRow renders product details', (tester) async {
    final product = Product(
      id: 1,
      title: 'Test Product',
      brand: 'Test Brand',
      rating: 4.5,
      price: 99,
      description: 'desc',
      category: 'cat',
      thumbnail: 'https://dummyimage.com/100',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductRow(product: product, onTap: () {})),
      ),
    );

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.textContaining('Test Brand'), findsOneWidget);
    expect(find.textContaining('4.5'), findsOneWidget);
    expect(find.textContaining('99'), findsOneWidget);
  });
}
