class Product {
  final int id;
  final String title;
  final String brand;
  final String category;
  final double price;
  final double rating;
  final String description;
  final String thumbnail;

  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.category,
    required this.price,
    required this.rating,
    required this.description,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    return Product(
      id: j['id'] as int,
      title: (j['title'] as String?)?.trim() ?? '',
      brand: (j['brand'] as String?)?.trim() ?? '',
      category: (j['category'] as String?)?.trim() ?? '',
      price: (j['price'] as num?)?.toDouble() ?? 0.0,
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      description: (j['description'] as String?)?.trim() ?? '',
      thumbnail: (j['thumbnail'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'brand': brand,
    'category': category,
    'price': price,
    'rating': rating,
    'description': description,
    'thumbnail': thumbnail,
  };
}
