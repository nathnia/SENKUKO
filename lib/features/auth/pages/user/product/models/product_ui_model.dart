class ProductUI {
  final String id;
  final String name;
  final String category;
  final String variantName;

  // Harga yang sedang dipakai sesuai customer
  final int price;

  final int normalPrice;
  final int memberPrice;
  final int grosirPrice;

  final String variantId;

  // Price List yang sedang dipakai
  final String priceListId;

  final String normalPriceListId;
  final String memberPriceListId;
  final String grosirPriceListId;

  final int grosirMinQty;

  final String? imageUrl;

  final int stock;

  final String description;

  ProductUI({
    required this.id,
    required this.name,
    required this.category,
    required this.variantName,

    required this.price,

    required this.normalPrice,
    required this.memberPrice,
    required this.grosirPrice,

    required this.variantId,

    required this.priceListId,

    required this.normalPriceListId,
    required this.memberPriceListId,
    required this.grosirPriceListId,

    required this.grosirMinQty,

    this.imageUrl,

    required this.stock,

    required this.description,
  });

  ProductUI copyWith({
    String? imageUrl,
    int? stock,
    String? description,
  }) {
    return ProductUI(
      id: id,
      name: name,
      category: category,
      variantName: variantName,

      price: price,

      normalPrice: normalPrice,
      memberPrice: memberPrice,
      grosirPrice: grosirPrice,

      variantId: variantId,

      priceListId: priceListId,

      normalPriceListId: normalPriceListId,
      memberPriceListId: memberPriceListId,
      grosirPriceListId: grosirPriceListId,

      grosirMinQty: grosirMinQty,

      imageUrl: imageUrl ?? this.imageUrl,

      stock: stock ?? this.stock,

      description: description ?? this.description,
    );
  }
}