class ProductUI {
  final String id;
  final String name;
  final String category;
  final String variantName;
  final int price;
  final String variantId;
  final String priceListId;
  final String? imageUrl;

  ProductUI({
    required this.id,
    required this.name,
    required this.category,
    required this.variantName,
    required this.price,
    required this.variantId,
    required this.priceListId,
    this.imageUrl,
  });

  ProductUI copyWith({
    String? imageUrl,
  }) {
    return ProductUI(
      id: id,
      name: name,
      category: category,
      variantName: variantName,
      price: price,
      variantId: variantId,
      priceListId: priceListId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}