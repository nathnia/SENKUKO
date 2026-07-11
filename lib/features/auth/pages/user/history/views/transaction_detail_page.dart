import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/transaction_detail_controller.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Hapus instance lama jika ada agar argumen baru diproses setiap kali
    if (Get.isRegistered<TransactionDetailController>()) {
      Get.delete<TransactionDetailController>();
    }
    final controller = Get.put(TransactionDetailController());

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi"), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final trx = controller.detail.value;

        if (trx == null) {
          return const Center(child: Text("Data tidak ditemukan"));
        }

        final items = trx["items"] as List<dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //-----------------------
              // STATUS
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: Colors.green),

                      const SizedBox(height: 10),

                      Text(
                        trx["invoice_number"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Chip(
                        backgroundColor: Colors.green.shade100,
                        label: Text(
                          controller.statusText(trx["status"].toString()),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //-----------------------
              // CUSTOMER
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const Divider(),

                      Text(
                        trx["customer_name"] ?? "-",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //-----------------------
              // ALAMAT
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Alamat Pengiriman",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const Divider(),

                      Text(trx["delivery_address"] ?? ""),

                      const SizedBox(height: 5),

                      Text(
                        "${trx["delivery_subregion"]}, ${trx["delivery_region"]}",
                      ),

                      Text(trx["delivery_city"]),

                      if ((trx["delivery_note"] ?? "")
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),

                        const Text(
                          "Catatan",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text(trx["delivery_note"]),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //-----------------------
              // PRODUK
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Produk",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),

                      const Divider(),

                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shopping_bag),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["variant_name"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      item["price_list_name"],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "${item["qty"]} x ${controller.rupiah(item["unit_price"])}",
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                controller.rupiah(item["subtotal"]),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //-----------------------
              // RINGKASAN
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Ringkasan Pembayaran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),

                      const Divider(),

                      _row("Subtotal", controller.rupiah(trx["subtotal"])),

                      const SizedBox(height: 10),

                      _row("Diskon", controller.rupiah(trx["total_discount"])),

                      const Divider(),

                      _row(
                        "Grand Total",
                        controller.rupiah(trx["grand_total"]),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //-----------------------
              // PEMBAYARAN
              //-----------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(
                        "Metode",
                        trx["payment_method"].toString().toUpperCase(),
                      ),

                      const SizedBox(height: 10),

                      _row("Status Pembayaran", trx["payment_status"]),

                      const SizedBox(height: 10),

                      _row("Tanggal", trx["transacted_at"]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String title, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
