import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cart/controller/cart_controller.dart';
import '../../product/services/transaction_service.dart';

class CheckoutController extends GetxController {
  final cart = Get.find<CartController>();

  final box = GetStorage();

  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final regionController = TextEditingController();
  final subregionController = TextEditingController();
  final noteController = TextEditingController();

  var paymentMethod = "cod".obs;

  final methods = [
    {"label": "COD", "value": "cod"},
    {"label": "Transfer Bank", "value": "bank_transfer"},
    {"label": "QRIS", "value": "qris"},
    {"label": "GoPay", "value": "gopay"},
    {"label": "ShopeePay", "value": "shopeepay"},
  ];

  @override
  void onInit() {
    super.onInit();

    final user = box.read("user");

    if (user != null) {
      addressController.text = user["address"] ?? "";
      cityController.text = user["city"] ?? "";
      regionController.text = user["region"] ?? "";
      subregionController.text = user["subregion"] ?? "";
    }
  }

  void changeMethod(String method) {
    paymentMethod.value = method;
  }

  Future<void> checkout({
    required bool fromCart,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      Get.snackbar("Error", "Tidak ada produk");
      return;
    }

    final result = await TransactionService.createTransaction(
      items: items,
      paymentMethod: paymentMethod.value,
      address: addressController.text,
      city: cityController.text,
      region: regionController.text,
      subregion: subregionController.text,
      note: noteController.text,
    );

    if (result == null) {
      Get.snackbar("Checkout Gagal", "Terjadi kesalahan");
      return;
    }

    if (fromCart) {
      cart.removeSelectedItems();
    }

    // ==========================
    // COD
    // ==========================
    if (result["payment_method"] == "cod") {
      Get.offAllNamed(
        "/order-success",
        arguments: {
          "invoice": result["invoice_number"],
          "total": result["grand_total"],
          "status": result["status"],
        },
      );

      return;
    }

    // ==========================
    // MIDTRANS
    // ==========================
    final redirectUrl = result["redirect_url"];

if (redirectUrl != null) {
  final uri = Uri.parse(redirectUrl);

  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  Get.defaultDialog(
    title: "Pembayaran Dibuat",
    middleText:
        "Silakan selesaikan pembayaran di Midtrans. Setelah pembayaran berhasil, cek status pesanan pada halaman Riwayat Pesanan.",
    textConfirm: "Lihat Riwayat",
    textCancel: "Nanti",
    onConfirm: () {
      Get.back();
      Get.offAllNamed("/history");
    },
  );

  return;
}
  }

  @override
  void onClose() {
    addressController.dispose();
    cityController.dispose();
    regionController.dispose();
    subregionController.dispose();
    noteController.dispose();

    super.onClose();
  }
}
