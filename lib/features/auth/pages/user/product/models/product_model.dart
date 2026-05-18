class Product {
  final String id;
  final String name;
  final String description;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category_name'] ?? '',
    );
  }
}