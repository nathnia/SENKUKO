class PromotionModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final String type;
  final String validFrom;
  final String validTo;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final bool stackable;

  PromotionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.type,
    required this.validFrom,
    required this.validTo,
    required this.usageLimit,
    required this.usageCount,
    required this.isActive,
    required this.stackable,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      code: json["code"] ?? "",
      description: json["description"] ?? "",
      type: json["type"] ?? "",
      validFrom: json["valid_from"] ?? "",
      validTo: json["valid_to"] ?? "",
      usageLimit: json["usage_limit"] ?? 0,
      usageCount: json["usage_count"] ?? 0,
      isActive: json["is_active"] == 1,
      stackable: json["stackable"] == 1,
    );
  }
}