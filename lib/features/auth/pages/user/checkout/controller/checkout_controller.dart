// lib/features/auth/pages/user/checkout/controller/checkout_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/product/services/transaction_service.dart';

class CheckoutController extends GetxController {
  final cart = Get.find<CartController>();
  final box = GetStorage();

  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final regionController = TextEditingController();
  final subregionController = TextEditingController();
  final noteController = TextEditingController();

  var paymentMethod = "cod".obs;
  var isLoading = false.obs;

  final methods = [
    {"label": "COD", "value": "cod"},
    {"label": "Transfer Bank", "value": "bank_transfer"},
    {"label": "QRIS", "value": "qris"},
    {"label": "GoPay", "value": "gopay"},
    {"label": "ShopeePay", "value": "shopeepay"},
  ];

  Timer? _statusCheckTimer;

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

  // lib/features/auth/pages/user/checkout/controller/checkout_controller.dart
  Future<void> checkout({
    required bool fromCart,
    required List<CartItem> items,
  }) async {
    print("========== STARTING CHECKOUT ==========");
    print("Items count: ${items.length}");
    print("From cart: $fromCart");

    if (items.isEmpty) {
      Get.snackbar("Error", "Keranjang kosong");
      return;
    }

    // Validasi alamat pengiriman
    if (addressController.text.trim().isEmpty) {
      Get.snackbar("Error", "Alamat pengiriman harus diisi");
      return;
    }

    if (cityController.text.trim().isEmpty) {
      Get.snackbar("Error", "Kota harus diisi");
      return;
    }

    if (regionController.text.trim().isEmpty) {
      Get.snackbar("Error", "Kecamatan harus diisi");
      return;
    }

    isLoading.value = true;

    try {
      print("Calling createTransaction...");

      final result = await TransactionService.createTransaction(
        items: items,
        paymentMethod: paymentMethod.value,
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        region: regionController.text.trim(),
        subregion: subregionController.text.trim(),
        note: noteController.text.trim(),
      );

      if (result == null) {
        print("RESULT IS NULL — returning");
        Get.snackbar(
          "Checkout Gagal",
          "Terjadi kesalahan saat membuat transaksi. Silakan coba lagi.",
        );
        return;
      }

      print("Checking payment_method: ${result["payment_method"]}");
      print(
        "Checking payment_method cod: ${result["payment_method"] == "cod"}",
      );

      if (result == null) {
        Get.snackbar(
          "Checkout Gagal",
          "Terjadi kesalahan saat membuat transaksi. Silakan coba lagi.",
        );
        return;
      }

      // Hapus item dari cart jika dari cart
      if (fromCart) {
        cart.removeSelectedItems();
      }

      // COD Payment
      if (result["payment_method"] == "cod") {
        Get.offAllNamed(
          "/order-success",
          arguments: {
            "invoice": result["invoice_number"],
            "total": result["grand_total"],
            "status": result["status"] ?? "pending",
            "transaction_id": result["transaction_id"],
          },
        );
        return;
      }

      // Midtrans Payment
      final redirectUrl = result["redirect_url"];
      final transactionId =
          result["transaction_id"]?.toString() ?? result["id"]?.toString();

      print("Redirect URL: $redirectUrl");
      print("Transaction ID: $transactionId");

      if (redirectUrl != null && transactionId != null) {
        final uri = Uri.parse(redirectUrl);

        print("URI: $uri");
        print("URI scheme: ${uri.scheme}");
        print("URI host: ${uri.host}");

        try {
          final canLaunch = await canLaunchUrl(uri);
          print("Can launch: $canLaunch");

          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          print("Launched: $launched");

          if (!launched) {
            Get.snackbar("Error", "Gagal membuka halaman pembayaran");
            return;
          }

          _showPaymentDialog(transactionId, result);
        } catch (e) {
          print("LaunchUrl error: $e");
          Get.snackbar("Error", "Gagal membuka halaman pembayaran: $e");
        }
      } else {
        Get.snackbar("Error", "Data pembayaran tidak lengkap");
      }
    } catch (e, stackTrace) {
      isLoading.value = false;
      print("Checkout fatal error: $e");
      print("Stack trace: $stackTrace");
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    }
  }

  void _showPaymentDialog(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) {
    // Langsung mulai polling tanpa tunggu user tekan tombol
    _startStatusChecking(transactionId, transactionData);
  }

  void _startStatusChecking(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) {
    Get.defaultDialog(
      title: "Menunggu Pembayaran",
      content: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            "Selesaikan pembayaran di aplikasi/browser.\nStatus akan otomatis diperbarui.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _statusCheckTimer?.cancel();
              Get.back();
              Get.offAllNamed("/history");
            },
            child: const Text("Cek Nanti di Riwayat"),
          ),
        ],
      ),
      onWillPop: () async => false,
    );

    int attempts = 0;
    const maxAttempts = 20; // 20 x 3 detik = 60 detik

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      attempts++;
      print(
        "Polling attempt $attempts/$maxAttempts for transaction: $transactionId",
      );

      try {
        final statusResult = await TransactionService.checkPaymentStatus(
          transactionId,
        );

        if (statusResult == null) {
          print("No result on attempt $attempts");
          if (attempts >= maxAttempts) {
            timer.cancel();
            Get.back();
            _showTimeoutDialog(transactionId);
          }
          return;
        }

        // ✅ FIX: cek payment_status, bukan status
        final paymentStatus = statusResult["payment_status"]
            ?.toString()
            ?.toLowerCase();
        print("payment_status: $paymentStatus (attempt $attempts)");

        if (paymentStatus == "paid") {
          timer.cancel();
          Get.back();
          _showSuccessDialog(transactionData);
          return;
        }

        if (paymentStatus == "cancel" ||
            paymentStatus == "expire" ||
            paymentStatus == "failed") {
          timer.cancel();
          Get.back();
          _showFailedDialog();
          return;
        }

        // Masih pending, lanjut polling
        if (attempts >= maxAttempts) {
          timer.cancel();
          Get.back();
          _showTimeoutDialog(transactionId);
        }
      } catch (e) {
        print("Status check error (attempt $attempts): $e");
        if (attempts >= maxAttempts) {
          timer.cancel();
          Get.back();
          _showTimeoutDialog(transactionId);
        }
      }
    });
  }

  void _showSuccessDialog(Map<String, dynamic> transactionData) {
    Get.defaultDialog(
      title: "Pembayaran Berhasil!",
      middleText:
          "Pembayaran Anda telah berhasil diproses.\n\n"
          "Invoice: ${transactionData["invoice_number"] ?? "-"}\n"
          "Total: Rp ${transactionData["grand_total"] ?? 0}",
      textConfirm: "Lihat Detail",
      onConfirm: () {
        Get.back();
        Get.offAllNamed(
          "/order-success",
          arguments: {
            "invoice": transactionData["invoice_number"],
            "total": transactionData["grand_total"],
            "status": "paid",
            "transaction_id":
                transactionData["transaction_id"] ?? transactionData["id"],
          },
        );
      },
    );
  }

  void _showFailedDialog() {
    Get.defaultDialog(
      title: "Pembayaran Gagal",
      middleText: "Pembayaran Anda gagal atau dibatalkan. Silakan coba lagi.",
      textConfirm: "Coba Lagi",
      textCancel: "Lihat Riwayat",
      onConfirm: () {
        Get.back();
        Get.offAllNamed("/cart");
      },
      onCancel: () {
        Get.back();
        Get.offAllNamed("/history");
      },
    );
  }

  void _showTimeoutDialog(String transactionId) {
    Get.defaultDialog(
      title: "Waktu Habis",
      middleText:
          "Waktu pengecekan status pembayaran telah habis. "
          "Silakan cek status pembayaran secara manual di halaman Riwayat Pesanan.",
      textConfirm: "Cek Riwayat",
      textCancel: "Nanti",
      onConfirm: () {
        Get.back();
        Get.offAllNamed("/history");
      },
      onCancel: () {
        Get.back();
      },
    );
  }

  @override
  void onClose() {
    _statusCheckTimer?.cancel();
    addressController.dispose();
    cityController.dispose();
    regionController.dispose();
    subregionController.dispose();
    noteController.dispose();
    super.onClose();
  }
}