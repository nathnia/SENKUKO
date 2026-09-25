class VoucherModel {
  final String id;
  final String code;
  final String promotionName;
  final String promotionCode;
  final String status;
  final String validFrom;
  final String validTo;
  final int usageLimit;
  final int usageCount;
  final bool isPublic;

  VoucherModel({
    required this.id,
    required this.code,
    required this.promotionName,
    required this.promotionCode,
    required this.status,
    required this.validFrom,
    required this.validTo,
    required this.usageLimit,
    required this.usageCount,
    required this.isPublic,
  });

  DateTime? get validFromDate => DateTime.tryParse(validFrom);

  DateTime? get validToDate => DateTime.tryParse(validTo);

  bool get isUpcoming =>
      validFromDate != null && DateTime.now().isBefore(validFromDate!);

  bool get isExpired =>
      validToDate != null && DateTime.now().isAfter(validToDate!);

  bool get isValidNow {
    return status.toLowerCase() == 'active' && !isUpcoming && !isExpired;
  }

  static bool _parsePublicValue(Map<String, dynamic> json) {
    final value =
        json['is_public'] ??
        json['public'] ??
        json['visibility'] ??
        json['is_published'] ??
        json['published'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'public' ||
        normalized == 'published' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes';
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      promotionName: json['promotion_name'] ?? '',
      promotionCode: json['promotion_code'] ?? '',
      status: json['status'] ?? '',
      validFrom: json['valid_from'] ?? json['validFrom'] ?? '',
      validTo: json['valid_to'] ?? json['validTo'] ?? '',
      usageLimit: json['usage_limit'] ?? 0,
      usageCount: json['usage_count'] ?? 0,
      isPublic: _parsePublicValue(json),
    );
  }
}
