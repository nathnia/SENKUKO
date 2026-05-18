import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/features/auth/pages/user/checkout/binding/checkout_binding.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/views/checkout_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductUI product;

  const ProductDetailPage({super.key, required this.product});

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Detail Produk"),
        backgroundColor: AppColors.card,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          //IMAGE
          Container(
            height: 250,
            color: AppColors.border,
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.image, size: 100)),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //INFO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Text(
                              formatRupiah(product.price),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              product.category,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),

                            const Spacer(),

                            const Text(
                              "Stok Tersedia",
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          product.variantName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  //DESKRIPSI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.card,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deskripsi Produk",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Deskripsi belum tersedia dari API",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          //BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.card,
            child: Row(
              children: [
                //MASUKKAN KERANJANG
                Expanded(
                  child: AppButton(
                    text: "Masukkan Keranjang",
                    outlined: true,
                    onPressed: () {
                      cart.addItem(
                        product.id,
                        product.name,
                        product.price,
                        product.variantId,
                        product.priceListId,
                        product.imageUrl,
                      );

                      Get.snackbar(
                        "Berhasil",
                        "Produk masuk ke keranjang",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                //BELI SEKARANG
                Expanded(
                  child: AppButton(
                    text: "Beli Sekarang",
                    onPressed: () {
                      showBuyNowSheet(context, product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//OVERLAY

void showBuyNowSheet(BuildContext context, ProductUI product) {
  int qty = 1;

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,

    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),

            child: Container(
              color: Colors.black.withOpacity(0.3),

              child: GestureDetector(
                onTap: () {},

                child: Align(
                  alignment: Alignment.bottomCenter,

                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.border,
                                      child: const Icon(Icons.image),
                                    ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(product.price),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jumlah"),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (qty > 1) {
                                      setState(() => qty--);
                                    }
                                  },
                                ),

                                Text("$qty"),

                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() => qty++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total"),
                            Text(
                              formatRupiah(product.price * qty),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              //LANGSUNG KE CHECKOUT (TANPA CART)
                              Get.to(
                                () => CheckoutPage(
                                  directItems: [
                                    CartItem(
                                      id: product.id,
                                      name: product.name,
                                      price: product.price,
                                      qty: qty,
                                      variantId: product.variantId,
                                      priceListId: product.priceListId,
                                      imageUrl: product.imageUrl,
                                    ),
                                  ],
                                  isFromCart: false,
                                ),
                                binding: CheckoutBinding(), // WAJIB
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text("Checkout"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
