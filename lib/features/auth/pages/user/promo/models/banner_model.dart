class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final int sortOrder;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.sortOrder,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json["id"] ?? "",
      imageUrl: json["image_url"] ?? "",
      title: json["title"] ?? "",
      sortOrder: json["sort_order"] ?? 0,
      isActive: json["is_active"] ?? true,
    );
  }
}