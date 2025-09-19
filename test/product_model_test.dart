import 'package:flutter_test/flutter_test.dart';
import 'package:products_explorer/models/product.dart';

void main() {
  test('Product.fromJson maps correctly', () {
    const json = {
      "id": 1,
      "title": "iPhone 9",
      "description": "An apple mobile which is nothing like apple",
      "price": 549,
      "discountPercentage": 12.96,
      "rating": 4.69,
      "stock": 94,
      "brand": "Apple",
      "category": "smartphones",
      "thumbnail": "https://i.dummyjson.com/data/products/1/thumbnail.jpg",
    };

    final p = Product.fromJson(json);
    expect(p.id, 1);
    expect(p.title, "iPhone 9");
    expect(p.brand, "Apple");
    expect(p.category, "smartphones");
    expect(p.price, 549.0);
    expect(p.rating, greaterThan(4.0));
    expect(p.thumbnail, contains('thumbnail.jpg'));
  });
}
