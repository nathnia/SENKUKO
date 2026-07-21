// lib/features/auth/pages/user/checkout/controller/checkout_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:senkuko/features/auth/login/services/auth_service.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/product/services/transaction_service.dart';

class CheckoutController extends GetxController {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  late final CartController cart = Get.find<CartController>();
  late final GetStorage box = GetStorage();

  // =========================================================================
  // FORM CONTROLLERS
  // =========================================================================

  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final regionController = TextEditingController();
  final subregionController = TextEditingController();
  final noteController = TextEditingController();
  final promoController = TextEditingController();
  final voucherController = TextEditingController();

  // =========================================================================
  // REACTIVE STATE
  // =========================================================================

  final isEditingAddress = false.obs;

  final paymentMethod = "cod".obs;

  final isLoading = false.obs;

  final methods = [
    {"label": "COD", "value": "cod"},
    {"label": "Transfer Bank", "value": "bank_transfer"},
    {"label": "GoPay", "value": "gopay"},
    {"label": "ShopeePay", "value": "shopeepay"},
  ].obs;

  // =========================================================================
  // PROMO & VOUCHER CODES
  // =========================================================================

  final promoCodes = <String>[].obs;

  final voucherCodes = <String>[].obs;

  // =========================================================================
  // DISCOUNT RESULT FROM BACKEND
  // =========================================================================

  final promoDiscountAmount = 0.obs;

  final voucherDiscountAmount = 0.obs;

  final totalPrice = 0.obs;

  final discount = 0.obs;

  // =========================================================================
  // PRICE LIST
  // =========================================================================

  final RxString? selectedPriceListId = RxString('');

  // =========================================================================
  // PAYMENT TIMER
  // =========================================================================

  Timer? _statusCheckTimer;

  // =========================================================================
  // CHANGE PAYMENT METHOD
  // =========================================================================

  void changeMethod(String? method) {
    if (method == null || method.isEmpty) return;

    paymentMethod.value = method;
  }

  // =========================================================================
  // RESOLVE VARIANT ID
  // =========================================================================

  String? _resolveVariantId(dynamic item) {
    try {
      return item.variantId?.toString() ??
          item.productVariantId?.toString() ??
          item.id?.toString();
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // PREVIEW DISCOUNTS
  // =========================================================================

  Future<void> previewDiscounts({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    // -----------------------------------------------------------------------
    // Jika tidak ada item
    // -----------------------------------------------------------------------

    if (items.isEmpty) {
      promoDiscountAmount.value = 0;
      voucherDiscountAmount.value = 0;
      discount.value = 0;
      totalPrice.value = subtotal;

      return;
    }

    // -----------------------------------------------------------------------
    // Pastikan item memiliki variant ID
    // -----------------------------------------------------------------------

    final List<Map<String, dynamic>> mappedItems = [];

    for (final item in items) {
      final variantId = _resolveVariantId(item);

      if (variantId != null && variantId.isNotEmpty) {
        mappedItems.add({
          "product_variant_id": variantId,
          "qty": item.qty,

          if (item.priceListId != null &&
              item.priceListId.toString().isNotEmpty)
            "price_list_id": item.priceListId.toString(),
        });
      }
    }

    // -----------------------------------------------------------------------
    // Jika tidak ada variant ID
    // -----------------------------------------------------------------------

    if (mappedItems.isEmpty) {
      promoDiscountAmount.value = 0;
      voucherDiscountAmount.value = 0;
      discount.value = 0;
      totalPrice.value = subtotal;

      return;
    }

    isLoading.value = true;

    try {
      // =====================================================================
      // REQUEST PREVIEW KE BACKEND
      // =====================================================================

      final response = await TransactionService.createTransaction(
        items: items,

        paymentMethod: paymentMethod.value,

        address: addressController.text.trim(),

        city: cityController.text.trim(),

        region: regionController.text.trim(),

        subregion: subregionController.text.trim(),

        note: noteController.text.trim(),

        promoCodes: promoCodes.toList(),

        voucherCodes: voucherCodes.toList(),

        priceListId: priceListId,

        previewOnly: true,
      );

      // =====================================================================
      // JIKA RESPONSE NULL
      // =====================================================================

      if (response == null) {
        promoDiscountAmount.value = 0;
        voucherDiscountAmount.value = 0;
        discount.value = 0;
        totalPrice.value = subtotal;

        return;
      }

      // =====================================================================
      // PARSING RESPONSE
      // =====================================================================

      /*
      TransactionService kamu mengembalikan:

      data dari response API.

      Contoh:

      {
        "grand_total": 90000,
        "applied_promotions": [
          {
            "discount_type": "voucher",
            "discount_amount": 10000
          }
        ]
      }

      */

      final dynamic rawData = response['data'] ?? response;

      final Map<String, dynamic> data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      // =====================================================================
      // AMBIL APPLIED PROMOTIONS
      // =====================================================================

      final List appliedPromotions = data['applied_promotions'] is List
          ? List.from(data['applied_promotions'])
          : [];

      int promoDiscount = 0;

      int voucherDiscount = 0;

      // =====================================================================
      // HITUNG DISKON DARI RESPONSE BACKEND
      // =====================================================================

      for (final entry in appliedPromotions) {
        if (entry is! Map) continue;

        final String discountType =
            (entry['discount_type'] ?? entry['type'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

        final int amount =
            (entry['discount_amount'] as num?)?.toInt() ??
            (entry['amount'] as num?)?.toInt() ??
            0;

        if (discountType.contains('voucher')) {
          voucherDiscount += amount;
        } else {
          promoDiscount += amount;
        }
      }

      // =====================================================================
      // AMBIL GRAND TOTAL DARI BACKEND
      // =====================================================================

      final int? backendGrandTotal = (data['grand_total'] as num?)?.toInt();

      // =====================================================================
      // FALLBACK TOTAL
      // =====================================================================

      final int calculatedTotal = subtotal - promoDiscount - voucherDiscount;

      // =====================================================================
      // UPDATE REACTIVE STATE
      // =====================================================================

      promoDiscountAmount.value = promoDiscount;

      voucherDiscountAmount.value = voucherDiscount;

      discount.value = promoDiscount + voucherDiscount;

      totalPrice.value =
          backendGrandTotal ?? calculatedTotal.clamp(0, subtotal);

      // =====================================================================
      // DEBUG
      // =====================================================================

      print("================ PREVIEW RESULT ================");

      print("Subtotal              : $subtotal");

      print("Promo Discount        : $promoDiscount");

      print("Voucher Discount      : $voucherDiscount");

      print("Backend Grand Total   : $backendGrandTotal");

      print("Final Total           : ${totalPrice.value}");

      print("==================================================");
    } catch (e) {
      // =====================================================================
      // ERROR
      // =====================================================================

      promoDiscountAmount.value = 0;

      voucherDiscountAmount.value = 0;

      discount.value = 0;

      totalPrice.value = subtotal;

      print("PREVIEW DISCOUNT ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // APPLY PROMO
  // =========================================================================

  Future<void> applyPromo({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    final code = promoController.text.trim().toUpperCase();

    if (code.isEmpty) return;

    if (promoCodes.contains(code)) {
      Get.snackbar(
        'Kode Promo',
        'Kode promo sudah digunakan.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      isLoading.value = true;

      // ---------------------------------------------------------------------
      // Buat list sementara untuk preview
      // ---------------------------------------------------------------------

      final List<String> trialPromos = [...promoCodes, code];

      final response = await TransactionService.createTransaction(
        items: items,

        paymentMethod: paymentMethod.value,

        address: addressController.text.trim(),

        city: cityController.text.trim(),

        region: regionController.text.trim(),

        subregion: subregionController.text.trim(),

        note: noteController.text.trim(),

        promoCodes: trialPromos,

        voucherCodes: voucherCodes.toList(),

        priceListId: priceListId,

        previewOnly: true,
      );

      if (response == null) {
        Get.snackbar(
          'Kode Promo',
          'Kode tidak valid atau preview gagal.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // Ambil response
      // ---------------------------------------------------------------------

      final dynamic rawData = response['data'] ?? response;

      final Map<String, dynamic> data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      final List appliedPromotions = data['applied_promotions'] is List
          ? List.from(data['applied_promotions'])
          : [];

      // ---------------------------------------------------------------------
      // Cek apakah ada promo yang diterapkan
      // ---------------------------------------------------------------------

      int promoDiscount = 0;

      for (final entry in appliedPromotions) {
        if (entry is! Map) continue;

        final type = (entry['discount_type'] ?? entry['type'] ?? '')
            .toString()
            .toLowerCase();

        final amount =
            (entry['discount_amount'] as num?)?.toInt() ??
            (entry['amount'] as num?)?.toInt() ??
            0;

        if (!type.contains('voucher')) {
          promoDiscount += amount;
        }
      }

      if (promoDiscount <= 0) {
        Get.snackbar(
          'Kode Promo',
          'Kode tidak valid atau tidak berlaku untuk pesanan ini.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // Simpan promo
      // ---------------------------------------------------------------------

      if (!promoCodes.contains(code)) {
        promoCodes.add(code);
      }

      promoController.clear();

      // ---------------------------------------------------------------------
      // Preview ulang
      // ---------------------------------------------------------------------

      await previewDiscounts(
        subtotal: subtotal,
        items: items,
        priceListId: priceListId,
      );
    } catch (e) {
      Get.snackbar(
        'Kode Promo',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // APPLY VOUCHER
  // =========================================================================

  Future<void> applyVoucher({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    final code = voucherController.text.trim().toUpperCase();

    if (code.isEmpty) return;

    if (voucherCodes.contains(code)) {
      Get.snackbar(
        'Kode Voucher',
        'Kode voucher sudah digunakan.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      isLoading.value = true;

      // ---------------------------------------------------------------------
      // Buat list sementara
      // ---------------------------------------------------------------------

      final List<String> trialVouchers = [...voucherCodes, code];

      // ---------------------------------------------------------------------
      // PREVIEW KE BACKEND
      // ---------------------------------------------------------------------

      final response = await TransactionService.createTransaction(
        items: items,

        paymentMethod: paymentMethod.value,

        address: addressController.text.trim(),

        city: cityController.text.trim(),

        region: regionController.text.trim(),

        subregion: subregionController.text.trim(),

        note: noteController.text.trim(),

        promoCodes: promoCodes.toList(),

        voucherCodes: trialVouchers,

        priceListId: priceListId,

        previewOnly: true,
      );

      // ---------------------------------------------------------------------
      // RESPONSE NULL
      // ---------------------------------------------------------------------

      if (response == null) {
        Get.snackbar(
          'Kode Voucher',
          'Kode tidak valid atau preview gagal.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // PARSE RESPONSE
      // ---------------------------------------------------------------------

      final dynamic rawData = response['data'] ?? response;

      final Map<String, dynamic> data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      final List appliedPromotions = data['applied_promotions'] is List
          ? List.from(data['applied_promotions'])
          : [];

      // ---------------------------------------------------------------------
      // HITUNG DISKON VOUCHER
      // ---------------------------------------------------------------------

      int voucherDiscount = 0;

      for (final entry in appliedPromotions) {
        if (entry is! Map) continue;

        final type = (entry['discount_type'] ?? entry['type'] ?? '')
            .toString()
            .toLowerCase();

        final amount =
            (entry['discount_amount'] as num?)?.toInt() ??
            (entry['amount'] as num?)?.toInt() ??
            0;

        if (type.contains('voucher')) {
          voucherDiscount += amount;
        }
      }

      // ---------------------------------------------------------------------
      // VOUCHER VALID
      // ---------------------------------------------------------------------

      if (voucherDiscount <= 0) {
        Get.snackbar(
          'Kode Voucher',
          'Kode tidak valid atau tidak berlaku untuk pesanan ini.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // SIMPAN VOUCHER
      // ---------------------------------------------------------------------

      if (!voucherCodes.contains(code)) {
        voucherCodes.add(code);
      }

      voucherController.clear();

      // ---------------------------------------------------------------------
      // PREVIEW ULANG
      // ---------------------------------------------------------------------

      await previewDiscounts(
        subtotal: subtotal,
        items: items,
        priceListId: priceListId,
      );

      Get.snackbar(
        'Voucher Berhasil',
        'Voucher $code berhasil diterapkan.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Kode Voucher',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // REMOVE PROMO
  // =========================================================================

  Future<void> removePromoCode(
    String code, {
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    promoCodes.remove(code);

    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );
  }

  // =========================================================================
  // REMOVE VOUCHER
  // =========================================================================

  Future<void> removeVoucherCode(
    String code, {
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    voucherCodes.remove(code);

    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );
  }

  // =========================================================================
  // SYNC PROFILE
  // =========================================================================

  void syncProfileToControllers(Map<String, dynamic>? user) {
    if (user == null) return;

    addressController.text = (user["address"] ?? "").toString();

    cityController.text = (user["city"] ?? "").toString();

    regionController.text = (user["region"] ?? "").toString();

    subregionController.text = (user["subregion"] ?? "").toString();
  }

  // =========================================================================
  // INIT
  // =========================================================================

  @override
  void onInit() {
    super.onInit();

    final savedUser = box.read("user");

    if (savedUser is Map) {
      syncProfileToControllers(Map<String, dynamic>.from(savedUser));
    }

    loadProfile();
  }

  // =========================================================================
  // LOAD PROFILE
  // =========================================================================

  Future<void> loadProfile() async {
    isLoading.value = true;

    try {
      final user = await AuthService.getProfile();

      if (user != null) {
        syncProfileToControllers(user);

        await box.write("user", user);
      }
    } catch (e) {
      print("LOAD PROFILE ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CHECKOUT FINAL
  // =========================================================================

  Future<void> checkout({
    required bool fromCart,
    required List<dynamic> items,
    String? promoCode,
    String? voucherCode,
    String? priceListId,
  }) async {
    // -----------------------------------------------------------------------
    // VALIDASI ALAMAT
    // -----------------------------------------------------------------------

    if (cityController.text.trim().isEmpty ||
        regionController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Lengkapi data alamat pengiriman.');

      return;
    }

    if (items.isEmpty) {
      Get.snackbar('Error', 'Tidak ada produk untuk checkout.');

      return;
    }

    isLoading.value = true;

    try {
      // =====================================================================
      // GABUNGKAN KODE YANG SUDAH DIAPPLY
      // =====================================================================

      final List<String> finalPromoCodes = [...promoCodes];

      final List<String> finalVoucherCodes = [...voucherCodes];

      // ---------------------------------------------------------------------
      // Jika ada kode dari parameter dan belum ada di list
      // ---------------------------------------------------------------------

      if (promoCode != null && promoCode.trim().isNotEmpty) {
        final code = promoCode.trim().toUpperCase();

        if (!finalPromoCodes.contains(code)) {
          finalPromoCodes.add(code);
        }
      }

      if (voucherCode != null && voucherCode.trim().isNotEmpty) {
        final code = voucherCode.trim().toUpperCase();

        if (!finalVoucherCodes.contains(code)) {
          finalVoucherCodes.add(code);
        }
      }

      // =====================================================================
      // TRANSAKSI FINAL
      // =====================================================================

      final result = await TransactionService.createTransaction(
        items: items,

        paymentMethod: paymentMethod.value,

        address: addressController.text.trim(),

        city: cityController.text.trim(),

        region: regionController.text.trim(),

        subregion: subregionController.text.trim(),

        note: noteController.text.trim(),

        promoCodes: finalPromoCodes,

        voucherCodes: finalVoucherCodes,

        priceListId: priceListId,

        previewOnly: false,
      );

      if (result == null) {
        throw Exception('Transaksi gagal dibuat.');
      }

      // =====================================================================
      // HAPUS CART
      // =====================================================================

      if (fromCart) {
        cart.removeSelectedItems();
      }

      // =====================================================================
      // COD
      // =====================================================================

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

      // =====================================================================
      // PAYMENT GATEWAY
      // =====================================================================

      final String? redirectUrl = result["redirect_url"] as String?;

      final String? transactionId = (result["transaction_id"] ?? result["id"])
          ?.toString();

      if (redirectUrl != null && transactionId != null) {
        final uri = Uri.parse(redirectUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          _showPaymentDialog(transactionId, result);
        } else {
          Get.snackbar('Error', 'Tidak dapat membuka halaman pembayaran.');
        }
      } else {
        Get.snackbar('Error', 'Data pembayaran tidak lengkap.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // PAYMENT DIALOG
  // =========================================================================

  void _showPaymentDialog(String transactionId, Map<String, dynamic> data) {
    _startStatusChecking(transactionId, data);
  }

  // =========================================================================
  // PAYMENT STATUS POLLING
  // =========================================================================

  void _startStatusChecking(String transactionId, Map<String, dynamic> data) {
    Get.defaultDialog(
      title: "Menunggu Pembayaran",

      barrierDismissible: false,

      content: Column(
        children: const [
          SizedBox(height: 16),

          CircularProgressIndicator(),

          SizedBox(height: 16),

          Text(
            "Selesaikan pembayaran di aplikasi/browser.\n"
            "Status akan otomatis diperbarui.",
            textAlign: TextAlign.center,
          ),
        ],
      ),

      confirm: TextButton(
        onPressed: () {
          _statusCheckTimer?.cancel();

          Get.back();

          Get.offAllNamed("/history");
        },

        child: const Text("Cek Nanti di Riwayat"),
      ),
    );

    int attempts = 0;

    const maxAttempts = 20;

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      attempts++;

      try {
        final statusResult = await TransactionService.checkPaymentStatus(
          transactionId,
        );

        if (statusResult == null) {
          if (attempts >= maxAttempts) {
            _handleTimeout(transactionId);
          }

          return;
        }

        final String paymentStatus =
            (statusResult["payment_status"] ?? statusResult["status"])
                .toString()
                .toLowerCase();

        // ---------------------------------------------------------------
        // PAID
        // ---------------------------------------------------------------

        if (paymentStatus == "paid") {
          _statusCheckTimer?.cancel();

          Get.back();

          _showSuccessDialog(data);

          return;
        }

        // ---------------------------------------------------------------
        // FAILED
        // ---------------------------------------------------------------

        if (paymentStatus == "cancel" ||
            paymentStatus == "expire" ||
            paymentStatus == "failed") {
          _statusCheckTimer?.cancel();

          Get.back();

          _showFailedDialog();

          return;
        }

        // ---------------------------------------------------------------
        // TIMEOUT
        // ---------------------------------------------------------------

        if (attempts >= maxAttempts) {
          _handleTimeout(transactionId);
        }
      } catch (e) {
        print("PAYMENT POLLING ERROR: $e");

        if (attempts >= maxAttempts) {
          _handleTimeout(transactionId);
        }
      }
    });
  }

  // =========================================================================
  // TIMEOUT
  // =========================================================================

  void _handleTimeout(String transactionId) {
    _statusCheckTimer?.cancel();

    Get.back();

    _showTimeoutDialog(transactionId);
  }

  // =========================================================================
  // SUCCESS DIALOG
  // =========================================================================

  void _showSuccessDialog(Map<String, dynamic> transactionData) {
    Get.defaultDialog(
      title: "Pembayaran Berhasil!",

      middleText:
          "Pembayaran Anda berhasil diproses.\n\n"
          "Invoice: "
          "${transactionData["invoice_number"] ?? "-"}\n"
          "Total: "
          "${transactionData["grand_total"] ?? 0}",

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

  // =========================================================================
  // FAILED DIALOG
  // =========================================================================

  void _showFailedDialog() {
    Get.defaultDialog(
      title: "Pembayaran Gagal",

      middleText:
          "Pembayaran Anda gagal atau dibatalkan. "
          "Silakan coba lagi atau lihat riwayat pesanan.",

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

  // =========================================================================
  // TIMEOUT DIALOG
  // =========================================================================

  void _showTimeoutDialog(String transactionId) {
    Get.defaultDialog(
      title: "Waktu Habis",

      middleText:
          "Pengecekan status pembayaran telah berakhir. "
          "Silakan cek manual di halaman Riwayat Pesanan.",

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

  // =========================================================================
  // CLEANUP
  // =========================================================================

  @override
  void onClose() {
    _statusCheckTimer?.cancel();
    addressController.dispose();
    cityController.dispose();
    regionController.dispose();
    subregionController.dispose();
    noteController.dispose();
    promoController.dispose();
    voucherController.dispose();
    super.onClose();
  }
}
