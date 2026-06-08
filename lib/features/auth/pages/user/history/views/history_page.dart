import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/history_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String rupiah(int value) {
    return "Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(title: const Text("Pesanan Saya")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactions.isEmpty) {
          return const Center(child: Text("Belum ada transaksi"));
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            itemCount: controller.transactions.length,
            itemBuilder: (_, index) {
              final trx = controller.transactions[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    trx.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rupiah(trx.grandTotal)),
                      Text(trx.paymentMethod.toUpperCase()),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(trx.status).withOpacity(.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      trx.status,
                      style: TextStyle(
                        color: statusColor(trx.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
