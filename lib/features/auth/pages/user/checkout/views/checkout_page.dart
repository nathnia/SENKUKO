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

    final items = directItems ?? cart.selectedItems;

    final int total = items.fold(
      0,
      (sum, item) => sum + item.price * item.qty,
    );

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
              child: Column(
                children: [

                  const SizedBox(height: 12),

                  // ADDRESS
                  AppCard(
                    child: Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Alamat Pengiriman",
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                "Jl. Contoh No.123, Kota, Provinsi",
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Ganti",
                            style: TextStyle(
                              color: AppColors.primary,
                            ),
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
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 14),

                          child: Row(
                            children: [

                              // IMAGE
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),

                                child: item.imageUrl != null &&
                                        item.imageUrl!
                                            .isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color:
                                            AppColors.border,
                                        child: const Icon(
                                            Icons.image),
                                      ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      formatRupiah(
                                          item.price),
                                      style:
                                          const TextStyle(
                                        color: AppColors
                                            .primary,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "x${item.qty}",
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

                        const Divider(height: 24),

                        rowHarga(
                          "Total",
                          total,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // BOTTOM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),

            child: Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text("Total"),

                      Text(
                        formatRupiah(total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget rowHarga(
    String title,
    int value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [

        Text(title),

        Text(
          "Rp $value",
          style: TextStyle(
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.normal,
            color: isTotal
                ? AppColors.primary
                : Colors.black,
          ),
        ),
      ],
    );
  }
}