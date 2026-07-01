class ProductUI {
  final String id;
  final String name;
  final String category;
  final String variantName;

  final int normalPrice;
  final int memberPrice;
  final int grosirPrice;

  final String variantId;

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

    required this.normalPrice,
    required this.memberPrice,
    required this.grosirPrice,

    required this.variantId,

    required this.normalPriceListId,
    required this.memberPriceListId,
    required this.grosirPriceListId,

    required this.grosirMinQty,

    this.imageUrl,
    required this.description,
    required this.stock,
  });

  ProductUI copyWith({String? imageUrl, int? stock, String? description}) {
    return ProductUI(
      id: id,
      name: name,
      category: category,
      variantName: variantName,

      description: description ?? this.description,

      normalPrice: normalPrice,
      memberPrice: memberPrice,
      grosirPrice: grosirPrice,

      variantId: variantId,

      normalPriceListId: normalPriceListId,
      memberPriceListId: memberPriceListId,
      grosirPriceListId: grosirPriceListId,

      grosirMinQty: grosirMinQty,

      stock: stock ?? this.stock,

      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
