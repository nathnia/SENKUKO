import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItem>? directItems;
  final bool isFromCart;

  const CheckoutPage({super.key, this.directItems, this.isFromCart = false});

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final checkout = Get.find<CheckoutController>();

    final items = directItems ?? cart.selectedItems;

    final int total = items.fold(0, (sum, item) => sum + item.price * item.qty);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
  children: [
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ALAMAT
            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: checkout.addressController,
                    decoration: const InputDecoration(
                      labelText: "Alamat",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: checkout.cityController,
                    decoration: const InputDecoration(
                      labelText: "Kota",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: checkout.regionController,
                    decoration: const InputDecoration(
                      labelText: "Kecamatan",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: checkout.subregionController,
                    decoration: const InputDecoration(
                      labelText: "Kelurahan",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: checkout.noteController,
                    decoration: const InputDecoration(
                      labelText: "Catatan",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // PRODUK
            AppCard(
              child: Column(
                children: items.map((item) {
                  return ListTile(
                    leading:
                        item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image),

                    title: Text(item.name),

                    subtitle: Text(
                      formatRupiah(item.price),
                    ),

                    trailing: Text("x${item.qty}"),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // TOTAL
            AppCard(
              child: Column(
                children: [
                  rowHarga("Subtotal", total),
                  const SizedBox(height: 8),
                  rowHarga("Ongkir", 0),
                  const SizedBox(height: 8),
                  rowHarga("Diskon", 0),
                  const Divider(),
                  rowHarga(
                    "Total",
                    total,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // METODE PEMBAYARAN
            AppCard(
              child: Obx(
                () => Column(
                  children:
                      checkout.methods.map((method) {
                        return RadioListTile<String>(
                          title: Text(
                            method["label"]!,
                          ),

                          value:
                              method["value"]!,

                          groupValue:
                              checkout
                                  .paymentMethod
                                  .value,

                          onChanged: (value) {
                            checkout.changeMethod(
                              value!,
                            );
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),

    Container(
      padding: const EdgeInsets.all(16),

      child: SizedBox(
        width: double.infinity,
        height: 50,

        child: AppButton(
          text: "Buat Pesanan",

          onPressed: () {
            checkout.checkout(
              fromCart: isFromCart,
              items: items,
            );
          },
        ),
      ),
    ),
  ],
),
    );
  }

  Widget rowHarga(String label, int price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight:
                isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        Text(
          formatRupiah(price),
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight:
                isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),

            const SizedBox(height: 16),

            const Text(
              "Pesanan Berhasil Dibuat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.offAllNamed('/home');
            },
            child: const Text("Kembali ke Beranda"),
          ),
        ],
      ),
    );        
  }
}