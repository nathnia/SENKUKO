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
  final String rewardType;
  final String freeItemName;

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
    this.rewardType = '',
    this.freeItemName = '',
  });

  DateTime? get validFromDate => DateTime.tryParse(validFrom);

  DateTime? get validToDate => DateTime.tryParse(validTo);

  bool get isUpcoming =>
      validFromDate != null && DateTime.now().isBefore(validFromDate!);

  bool get isExpired =>
      validToDate != null && DateTime.now().isAfter(validToDate!);

  bool get isValidNow => isActive && !isUpcoming && !isExpired;

  bool get isFreeItem {
    final normalizedType = '$type $rewardType $name $description'.toLowerCase();
    return normalizedType.contains('free_item') ||
        normalizedType.contains('free item') ||
        normalizedType.contains('gratis item') ||
        normalizedType.contains('gift') ||
        freeItemName.isNotEmpty;
  }

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
      isActive: json["is_active"] == 1 || json["is_active"] == true,
      stackable: json["stackable"] == 1 || json["stackable"] == true,
      rewardType:
          json["reward_type"]?.toString() ??
          json["discount_type"]?.toString() ??
          '',
      freeItemName: _firstString(json, [
        "free_item_name",
        "free_item",
        "item_name",
        "product_name",
        "reward_name",
        "reward_product_name",
        "free_product_name",
        "gift_item_name",
        "gift_product_name",
        "reward_product",
      ]),
    );
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null || value is bool || value is Map || value is List) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
