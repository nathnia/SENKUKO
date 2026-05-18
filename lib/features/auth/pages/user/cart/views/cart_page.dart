import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/binding/checkout_binding.dart';
import 'package:senkuko/features/auth/pages/user/checkout/views/checkout_page.dart';

class CartPage extends StatelessWidget {
  final cart = Get.find<CartController>();

  CartPage({super.key});

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => "${m[1]}.",
    )}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Keranjang"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Obx(() {
        if (cart.items.isEmpty) {
          return const Center(
            child: Text("Keranjang kosong"),
          );
        }

        return Column(
          children: [

            // SELECT ALL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: cart.isAllSelected,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      cart.toggleAll(value ?? false);
                    },
                  ),
                  const Text(
                    "Pilih Semua",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // LIST ITEM
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // CHECKBOX
                        Checkbox(
                          value: item.selected,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            cart.toggleItem(index);
                          },
                        ),

                        // IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 75,
                                  height: 75,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 75,
                                  height: 75,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                        ),

                        const SizedBox(width: 12),

                        // INFO
                        Expanded(
                          child: SizedBox(
                            height: 75,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  formatRupiah(item.price),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),

                                const Spacer(),

                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      qtyButton(
                                        Icons.remove,
                                        () => cart.decreaseQty(index),
                                      ),

                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          "${item.qty}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      qtyButton(
                                        Icons.add,
                                        () => cart.increaseQty(index),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

              child: Column(
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(fontSize: 15),
                      ),

                      Text(
                        formatRupiah(cart.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: AppButton(
                      text: "Checkout",
                      onPressed: cart.selectedItems.isEmpty
                          ? null
                          : () {
                              Get.to(
                                () => CheckoutPage(
                                  directItems:
                                      cart.selectedItems,
                                  isFromCart: true,
                                ),
                                binding: CheckoutBinding(),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),

      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}