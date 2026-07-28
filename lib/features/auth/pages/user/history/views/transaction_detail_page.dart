import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/transaction_detail_controller.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key});

  // ============================================================
  // DIALOG KONFIRMASI CANCEL
  // ============================================================

  void _showCancelConfirmation(
    BuildContext context,
    TransactionDetailController controller,
  ) {
    Get.defaultDialog(
      title: "Batalkan Transaksi?",
      middleText:
          "Apakah kamu yakin ingin membatalkan transaksi ini?\n\n"
          "Stock produk akan dikembalikan oleh sistem.",

      textConfirm: "Ya, Batalkan",
      textCancel: "Tidak",

      confirmTextColor: Colors.white,
      buttonColor: Colors.red,

      onConfirm: () async {
        Get.back();

        await controller.cancelTransaction();
      },

      onCancel: () {
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<TransactionDetailController>()) {
      Get.delete<TransactionDetailController>();
    }

    final controller = Get.put(
      TransactionDetailController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        centerTitle: true,
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final trx = controller.detail.value;

        if (trx == null) {
          return const Center(
            child: Text("Data tidak ditemukan"),
          );
        }

        // ============================================================
        // AMAN DARI NULL
        // ============================================================

        final List<dynamic> items =
            trx["items"] is List ? trx["items"] : [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [

              // ======================================================
              // STATUS
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: trx["status"]?.toString().toLowerCase() ==
                                "cancelled"
                            ? Colors.red
                            : Colors.green,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        trx["invoice_number"]?.toString() ?? "-",

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),

                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Chip(
                        backgroundColor:
                            trx["status"]?.toString().toLowerCase() ==
                                    "cancelled"
                                ? Colors.red.shade100
                                : Colors.green.shade100,

                        label: Text(
                          controller.statusText(
                            trx["status"]?.toString() ?? "-",
                          ),

                          style: TextStyle(
                            color:
                                trx["status"]
                                            ?.toString()
                                            .toLowerCase() ==
                                        "cancelled"
                                    ? Colors.red
                                    : Colors.green,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ======================================================
              // CUSTOMER
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

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
                        trx["customer_name"]?.toString() ?? "-",

                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ======================================================
              // ALAMAT
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Alamat Pengiriman",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const Divider(),

                      Text(
                        trx["delivery_address"]
                                ?.toString() ??
                            "-",
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "${trx["delivery_subregion"] ?? "-"}, "
                        "${trx["delivery_region"] ?? "-"}",
                      ),

                      Text(
                        trx["delivery_city"]
                                ?.toString() ??
                            "-",
                      ),

                      if ((trx["delivery_note"] ?? "")
                          .toString()
                          .isNotEmpty) ...[

                        const SizedBox(height: 12),

                        const Text(
                          "Catatan",

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          trx["delivery_note"]
                                  .toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ======================================================
              // PRODUK
              // ======================================================

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

                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),

                          child: Text(
                            "Detail produk tidak tersedia.",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),

                      ...items.map((item) {

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 14,
                          ),

                          child: Row(
                            children: [

                              Container(
                                width: 55,
                                height: 55,

                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),

                                child: const Icon(
                                  Icons.shopping_bag,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    Text(
                                      item["variant_name"]
                                              ?.toString() ??
                                          "-",

                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      item["price_list_name"]
                                              ?.toString() ??
                                          "-",

                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "${item["qty"] ?? 0} x "
                                      "${controller.rupiah(
                                        item["unit_price"],
                                      )}",
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                controller.rupiah(
                                  item["subtotal"],
                                ),

                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ======================================================
              // RINGKASAN
              // ======================================================

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

                      _row(
                        "Subtotal",
                        controller.rupiah(
                          trx["subtotal"],
                        ),
                      ),

                      const SizedBox(height: 10),

                      _row(
                        "Diskon",
                        controller.rupiah(
                          trx["total_discount"],
                        ),
                      ),

                      const Divider(),

                      _row(
                        "Grand Total",

                        controller.rupiah(
                          trx["grand_total"],
                        ),

                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ======================================================
              // PEMBAYARAN
              // ======================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      _row(
                        "Metode",

                        trx["payment_method"]
                                ?.toString()
                                .toUpperCase() ??
                            "-",
                      ),

                      const SizedBox(height: 10),

                      _row(
                        "Status Pembayaran",

                        controller.paymentStatusText(
                          trx["payment_status"]
                                  ?.toString() ??
                              "-",
                        ),
                      ),

                      const SizedBox(height: 10),

                      _row(
                        "Tanggal",

                        controller.formatDate(
                          trx["transacted_at"]
                                  ?.toString() ??
                              "-",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // BUTTON CANCEL
              // ======================================================

              if (controller.canCancelTransaction)

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCancelConfirmation(
                        context,
                        controller,
                      );
                    },

                    icon: const Icon(
                      Icons.cancel_outlined,
                    ),

                    label: const Text(
                      "Batalkan Transaksi",
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
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

  // ============================================================
  // ROW
  // ============================================================

  Widget _row(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Text(title),

        Flexible(
          child: Text(
            value,

            textAlign: TextAlign.end,

            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}