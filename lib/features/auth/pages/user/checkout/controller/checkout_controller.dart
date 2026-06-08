import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/product/services/transaction_service.dart';
import '../../cart/controller/cart_controller.dart';

class CheckoutController extends GetxController {
  final cart = Get.find<CartController>();

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
];

  void changeMethod(String method) {
    paymentMethod.value = method;
  }

  Future<void> checkout({
    required bool fromCart,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      Get.snackbar(
        "Error",
        "Tidak ada produk",
      );
      return;
    }

    if (addressController.text.isEmpty ||
        cityController.text.isEmpty ||
        regionController.text.isEmpty ||
        subregionController.text.isEmpty) {
      Get.snackbar(
        "Alamat Belum Lengkap",
        "Mohon isi alamat pengiriman",
      );
      return;
    }

    final success =
        await TransactionService.createTransaction(
      items: items,
      paymentMethod: paymentMethod.value,

      address: addressController.text,
      city: cityController.text,
      region: regionController.text,
      subregion: subregionController.text,
      note: noteController.text,
    );

    if (success) {
      if (fromCart) {
        cart.removeSelectedItems();
      }

      Get.offAllNamed('/order-success');
    } else {
      Get.snackbar(
        "Error",
        "Gagal membuat transaksi",
      );
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