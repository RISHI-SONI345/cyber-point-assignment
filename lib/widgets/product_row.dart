import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Hero(
        tag: 'product-${product.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.thumbnail,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
        ),
      ),
      title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${product.brand} — ⭐ ${product.rating.toStringAsFixed(1)}',
      ),
      trailing: Text('₹${product.price.toStringAsFixed(0)}'),
      onTap: onTap,
    );
  }
}
