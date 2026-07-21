class VoucherModel {
  final String id;
  final String code;
  final String promotionName;
  final String promotionCode;
  final String status;
  final int usageLimit;
  final int usageCount;

  VoucherModel({
    required this.id,
    required this.code,
    required this.promotionName,
    required this.promotionCode,
    required this.status,
    required this.usageLimit,
    required this.usageCount,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      promotionName: json['promotion_name'] ?? '',
      promotionCode: json['promotion_code'] ?? '',
      status: json['status'] ?? '',
      usageLimit: json['usage_limit'] ?? 0,
      usageCount: json['usage_count'] ?? 0,
    );
  }
}