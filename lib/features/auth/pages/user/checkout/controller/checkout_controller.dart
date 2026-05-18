import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/product/services/transaction_service.dart';
import '../../cart/controller/cart_controller.dart';

class CheckoutController extends GetxController {
  final cart = Get.find<CartController>();

  var paymentMethod = "cash".obs;

final methods = [
  {"label": "COD", "value": "cash"},
  {"label": "Transfer Bank", "value": "transfer"},
  {"label": "QRIS", "value": "qris"},
];

  void changeMethod(String method) {
  paymentMethod.value = method;
}

  Future<void> checkout({
  required bool fromCart,
  required List<CartItem> items,
}) async {
  print("🔥 CHECKOUT DIPANGGIL");
    if (items.isEmpty) {
      Get.snackbar("Error", "Tidak ada produk");
      return;
    }

    final success = await TransactionService.createTransaction(
      items: items,
      paymentMethod: paymentMethod.value,
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
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}