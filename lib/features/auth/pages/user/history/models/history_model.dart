class HistoryModel {
  final String id;
  final String invoiceNumber;
  final String status;
  final int grandTotal;
  final int subtotal;
  final int totalDiscount;
  final int paidAmount;
  final String paymentMethod;
  final String transactedAt;
  final String createdAt;

  HistoryModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.grandTotal,
    required this.subtotal,
    required this.totalDiscount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.transactedAt,
    required this.createdAt,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return double.parse(value).toInt();
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json["id"]?.toString() ?? "",
      invoiceNumber: json["invoice_number"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      grandTotal: _parseInt(json["grand_total"]),
      subtotal: _parseInt(json["subtotal"]),
      totalDiscount: _parseInt(json["total_discount"]),
      paidAmount: _parseInt(json["paid_amount"]),
      paymentMethod: json["payment_method"]?.toString() ?? "",
      transactedAt: json["transacted_at"]?.toString() ?? "",
      createdAt: json["created_at"]?.toString() ?? "",
    );
  }
}