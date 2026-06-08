import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';

import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItem>? directItems;
  final bool isFromCart;

  const CheckoutPage({
    super.key,
    this.directItems,
    this.isFromCart = false,
  });

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => "${m[1]}.",
        )}";
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final checkout = Get.find<CheckoutController>();

    final user = GetStorage().read("user");

    final items = directItems ?? cart.selectedItems;

    final int total =
        items.fold(0, (sum, item) => sum + (item.price * item.qty));

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          "Checkout",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // =========================
                  // ALAMAT PENGIRIMAN
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.location_on,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Alamat Pengiriman",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          user?["name"] ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          user?["phone"] ?? "-",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const Divider(height: 24),

                        Text(
                          checkout.addressController.text,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${checkout.subregionController.text}, ${checkout.regionController.text}",
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          checkout.cityController.text,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: checkout.noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Catatan untuk kurir (opsional)",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // PRODUK
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Produk Pesanan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 16),

                        ...items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        formatRupiah(item.price),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "x${item.qty}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // METODE PEMBAYARAN
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Metode Pembayaran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                          () => Column(
                            children:
                                checkout.methods.map((method) {
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: checkout.paymentMethod.value ==
                                            method["value"]
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: RadioListTile<String>(
                                  activeColor: Colors.green,
                                  title:
                                      Text(method["label"]!),
                                  value: method["value"]!,
                                  groupValue:
                                      checkout.paymentMethod.value,
                                  onChanged: (value) {
                                    checkout.changeMethod(
                                      value!,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // RINGKASAN
                  // =========================
                  AppCard(
                    child: Column(
                      children: [
                        rowHarga("Subtotal", total),

                        const SizedBox(height: 10),

                        rowHarga("Ongkir", 0),

                        const SizedBox(height: 10),

                        rowHarga("Diskon", 0),

                        const Divider(height: 24),

                        rowHarga(
                          "Total Pembayaran",
                          total,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // =========================
          // BOTTOM BAR
          // =========================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          formatRupiah(total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 170,
                    height: 50,
                    child: AppButton(
                      text:
                          "Bayar ${formatRupiah(total)}",
                      onPressed: () {
                        checkout.checkout(
                          fromCart: isFromCart,
                          items: items,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget rowHarga(
    String label,
    int price, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight:
                isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          formatRupiah(price),
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: FontWeight.bold,
            color:
                isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}