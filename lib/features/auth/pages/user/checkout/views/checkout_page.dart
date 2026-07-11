// lib/features/auth/pages/user/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';

class CheckoutPage extends StatelessWidget {
  /// Jika Checkout dipanggil langsung dari list produk (bukan dari keranjang)
  /// Anda dapat meng‑oper `directItems`. Bila `null`, otomatis pakai
  /// `cart.selectedItems`.
  final List<CartItem>? directItems;
  final bool isFromCart;

  const CheckoutPage({
    Key? key,
    this.directItems,
    this.isFromCart = false,
  }) : super(key: key);

  /// Helper format angka ke “Rp xxx.xxx”
  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------
    // 1.  Dapatkan controller & data yang dibutuhkan
    // -----------------------------------------------------------------
    final cart = Get.find<CartController>();
    final checkout = Get.find<CheckoutController>();
    final box = GetStorage();

    // Item yang akan di‑checkout (langsung atau dari keranjang)
    final List<CartItem> items = directItems ?? cart.selectedItems;

    // Sub‑total (tanpa ongkir, tanpa diskon)
    final int subtotal = items.fold<int>(0,
        (sum, it) => sum + (it.price * it.qty));

    // -----------------------------------------------------------------
    // 2.  Preview pertama kali (setelah frame dibangun)
    // -----------------------------------------------------------------
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Jika Anda memiliki price‑list, masukkan id‑nya di sini.
      checkout.previewDiscounts(
        subtotal: subtotal,
        items: items,
        priceListId: checkout.selectedPriceListId?.value.isNotEmpty == true
            ? checkout.selectedPriceListId!.value
            : null,
      );
    });

    // -----------------------------------------------------------------
    // 3.  UI
    // -----------------------------------------------------------------
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // 3.1  Konten utama (scrollable)
          // -----------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // ------------------- ALAMAT PENGIRIMAN -------------------
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Colors.green),
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

                        // Nama + No. Telepon (dari storage user)
                        Text(
                          box.read("user")?["name"] ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          box.read("user")?["phone"] ?? "-",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 24),

                        // ----- Alamat yang dapat diedit -----
                        Obx(() {
                          if (!checkout.isEditingAddress.value) {
                            // Tampilkan alamat yang tersimpan
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: checkout.addressController,
                                  builder: (context, value, _) {
                                    return Text(
                                      value.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        checkout.isEditingAddress.value = true,
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text("Edit"),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Mode edit
                          return Column(
                            children: [
                              TextField(
                                controller: checkout.addressController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: "Alamat Pengiriman",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        checkout.isEditingAddress.value = false;
                                        await checkout.loadProfile();
                                      },
                                      child: const Text("Batal"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          checkout.isEditingAddress.value =
                                              false,
                                      child: const Text("Simpan"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),

                        // Catatan untuk kurir (opsional)
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

                  // ------------------- PRODUK -------------------
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: (item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty)
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
                                        overflow: TextOverflow.ellipsis,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "x${item.qty}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ------------------- METODE PEMBAYARAN -------------------
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
                        Obx(() {
                          return Column(
                            children: checkout.methods.map((method) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: checkout.paymentMethod.value ==
                                            method["value"]
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: RadioListTile<String>(
                                  activeColor: Colors.green,
                                  title: Text(method["label"]!),
                                  value: method["value"]!,
                                  groupValue: checkout.paymentMethod.value,
                                  onChanged: (value) =>
                                      checkout.changeMethod(value!),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ------------------- PROMO & VOUCHER -------------------
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Promo & Voucher",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---- KODE PROMO ----
                        TextField(
                          controller: checkout.promoController,
                          onSubmitted: (_) => checkout.applyPromo(
                            subtotal: subtotal,
                            items: items,
                            priceListId: checkout.selectedPriceListId?.value
                                    .isNotEmpty ==
                                true
                                ? checkout
                                    .selectedPriceListId!.value
                                : null,
                          ),
                          decoration: InputDecoration(
                            labelText: "Kode Promo",
                            hintText: "Contoh: PROMO10",
                            prefixIcon: const Icon(Icons.local_offer),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: TextButton(
                              onPressed: () => checkout.applyPromo(
                                subtotal: subtotal,
                                items: items,
                                priceListId: checkout
                                        .selectedPriceListId?.value.isNotEmpty ==
                                    true
                                    ? checkout
                                        .selectedPriceListId!.value
                                    : null,
                              ),
                              child: const Text("Terapkan"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Daftar kode promo yang sudah ditambahkan
                        Obx(() {
                          if (checkout.promoCodes.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: checkout.promoCodes.map((code) {
                              return InputChip(
                                label: Text(code),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => checkout.removePromoCode(
                                  code,
                                  subtotal: subtotal,
                                  items: items,
                                  priceListId: checkout
                                          .selectedPriceListId?.value.isNotEmpty ==
                                      true
                                      ? checkout
                                          .selectedPriceListId!.value
                                      : null,
                                ),
                              );
                            }).toList(),
                          );
                        }),

                        const SizedBox(height: 16),

                        // ---- KODE VOUCHER ----
                        TextField(
                          controller: checkout.voucherController,
                          onSubmitted: (_) => checkout.applyVoucher(
                            subtotal: subtotal,
                            items: items,
                            priceListId: checkout.selectedPriceListId?.value
                                    .isNotEmpty ==
                                true
                                ? checkout
                                    .selectedPriceListId!.value
                                : null,
                          ),
                          decoration: InputDecoration(
                            labelText: "Kode Voucher",
                            hintText: "Contoh: VOUCHER50",
                            prefixIcon: const Icon(Icons.card_giftcard),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: TextButton(
                              onPressed: () => checkout.applyVoucher(
                                subtotal: subtotal,
                                items: items,
                                priceListId: checkout
                                        .selectedPriceListId?.value.isNotEmpty ==
                                    true
                                    ? checkout
                                        .selectedPriceListId!.value
                                    : null,
                              ),
                              child: const Text("Terapkan"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Daftar voucher yang sudah ditambahkan
                        Obx(() {
                          if (checkout.voucherCodes.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: checkout.voucherCodes.map((code) {
                              return InputChip(
                                label: Text(code),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => checkout.removeVoucherCode(
                                  code,
                                  subtotal: subtotal,
                                  items: items,
                                  priceListId: checkout
                                          .selectedPriceListId?.value.isNotEmpty ==
                                      true
                                      ? checkout
                                          .selectedPriceListId!.value
                                      : null,
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),

                  // ------------------- RINGKASAN -------------------
                  Obx(() {
                    final int promoDisc = checkout.promoDiscountAmount.value;
                    final int voucherDisc = checkout.voucherDiscountAmount.value;
                    final int total = checkout.totalPrice.value > 0
                        ? checkout.totalPrice.value
                        : subtotal - promoDisc - voucherDisc;

                    return AppCard(
                      child: Column(
                        children: [
                          rowHarga("Subtotal", subtotal),
                          const SizedBox(height: 10),
                          rowHarga("Ongkir", 0),
                          const SizedBox(height: 10),
                          rowHarga("Diskon Promo", promoDisc),
                          const SizedBox(height: 8),
                          rowHarga("Diskon Voucher", voucherDisc),
                          const SizedBox(height: 8),
                          rowHarga("Total Pembayaran", total,
                              isTotal: true),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // 3.2  Bottom bar (total + tombol bayar)
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // ----- TOTAL -----
                  Expanded(
                    child: Obx(() {
                      final int promoDisc = checkout.promoDiscountAmount.value;
                      final int voucherDisc = checkout.voucherDiscountAmount.value;
                      final int total = checkout.totalPrice.value > 0
                          ? checkout.totalPrice.value
                          : subtotal - promoDisc - voucherDisc;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(color: Colors.grey),
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
                      );
                    }),
                  ),

                  // ----- TOMBOL BAYAR -----
                  SizedBox(
                    width: 170,
                    height: 50,
                    child: Obx(() {
                      // Tampilkan loading ketika preview atau checkout sedang diproses
                      if (checkout.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final int promoDisc = checkout.promoDiscountAmount.value;
                      final int voucherDisc = checkout.voucherDiscountAmount.value;
                      final int total = checkout.totalPrice.value > 0
                          ? checkout.totalPrice.value
                          : subtotal - promoDisc - voucherDisc;

                      return AppButton(
                        text: "Bayar ${formatRupiah(total)}",
                        onPressed: () {
                          // Validasi alamat sebelum checkout
                          if (checkout.addressController.text.trim().isEmpty) {
                            Get.snackbar(
                              "Alamat kosong",
                              "Silakan isi alamat pengiriman.",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          checkout.checkout(
                            fromCart: isFromCart,
                            items: items,
                            promoCode: checkout.promoController.text.trim(),
                            voucherCode: checkout.voucherController.text.trim(),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Helper: Baris “label – amount”
  // -----------------------------------------------------------------
  Widget rowHarga(String label, int price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          formatRupiah(price),
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}