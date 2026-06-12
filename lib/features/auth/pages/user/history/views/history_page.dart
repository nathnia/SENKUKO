import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/history/controller/history_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String rupiah(int value) {
    return "Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
  }

  String formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
      case "completed":
      case "settlement":
      case "capture":
        return Colors.green;

      case "processing":
        return Colors.orange;

      case "pending":
      case "pending_payment":
        return Colors.blue;

      case "cancel":
      case "cancelled":
      case "expire":
      case "deny":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String statusText(String status) {
    switch (status.toLowerCase()) {
      case "paid":
      case "settlement":
      case "capture":
        return "Berhasil";

      case "pending":
      case "pending_payment":
        return "Menunggu Pembayaran";

      case "processing":
        return "Diproses";

      case "cancel":
      case "cancelled":
        return "Dibatalkan";

      case "expire":
        return "Kadaluarsa";

      case "deny":
        return "Ditolak";

      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan"),
        actions: [
          IconButton(
            onPressed: controller.refreshHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Belum ada transaksi",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshHistory,
          child: Column(
            children: [
              // Last refresh info
              if (!controller.isLoading.value)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Terakhir diperbarui: ${formatDate(controller.lastRefreshTime.value.toIso8601String())}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (controller.hasPendingTransactions)
                        const Text(
                          "• Memantau pembayaran...",
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.transactions.length,
                  itemBuilder: (_, index) {
                    final trx = controller.transactions[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          trx.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              rupiah(trx.grandTotal),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${trx.paymentMethod.toUpperCase()} • ${formatDate(trx.createdAt)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(trx.status).withOpacity(.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText(trx.status),
                            style: TextStyle(
                              color: statusColor(trx.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          // TODO: Navigate to transaction detail page
                          _showTransactionDetail(trx);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showTransactionDetail(dynamic transaction) {
    // Implement transaction detail dialog or page
    Get.defaultDialog(
      title: "Detail Transaksi",
      middleText:
          "Invoice: ${transaction.invoiceNumber}\n"
          "Status: ${statusText(transaction.status)}\n"
          "Total: ${rupiah(transaction.grandTotal)}",
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }
}