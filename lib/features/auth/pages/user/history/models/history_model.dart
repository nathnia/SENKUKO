class HistoryModel {
  final String id;
  final String invoiceNumber;
  final String status;
  final int grandTotal;
  final String paymentMethod;
  final String createdAt;

  HistoryModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.grandTotal,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json["id"] ?? "",
      invoiceNumber: json["invoice_number"] ?? "",
      status: json["status"] ?? "",
      grandTotal: json["grand_total"] ?? 0,
      paymentMethod: json["payment_method"] ?? "",
      createdAt: json["created_at"] ?? "",
    );
  }
}