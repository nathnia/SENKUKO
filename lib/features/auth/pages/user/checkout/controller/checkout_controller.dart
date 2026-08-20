import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/features/auth/pages/user/payment/view/payment_webview_page.dart';
import 'package:senkuko/features/auth/pages/user/promo/models/promotion_model.dart';
import 'package:senkuko/features/auth/pages/user/promo/services/promotion_service.dart';
import 'package:senkuko/features/auth/login/services/auth_service.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/product/services/transaction_service.dart';
import 'package:senkuko/features/auth/pages/user/service.user/cache_service.dart';

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
  final RxList<PromotionModel> promotions = <PromotionModel>[].obs;
  final Rx<PromotionModel?> selectedPromotion = Rx<PromotionModel?>(null);

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

        final type = (entry['discount_type'] ?? entry['type'] ?? '')
            .toString()
            .toLowerCase();

        final rewardType = (entry['reward_type'] ?? '')
            .toString()
            .toLowerCase();

        final amount =
            (entry['discount_amount'] as num?)?.toInt() ??
            (entry['amount'] as num?)?.toInt() ??
            0;

        final bool isVoucher =
            type.contains('voucher') ||
            type.contains('coupon') ||
            rewardType.contains('voucher') ||
            rewardType.contains('coupon');

        final bool isPromo =
            type.contains('promo') ||
            type.contains('promotion') ||
            rewardType.contains('promo') ||
            rewardType.contains('promotion') ||
            (!isVoucher && amount > 0);

        if (isVoucher) {
          voucherDiscount += amount;
        } else if (isPromo) {
          promoDiscount += amount;
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
      // SYNC DENGAN BACKEND JIKA BREAKDOWN TIDAK LENGKAP
      // =====================================================================

      if (backendGrandTotal != null) {
        final int backendDiscount = (subtotal - backendGrandTotal).clamp(
          0,
          subtotal,
        );
        final int parsedDiscount = promoDiscount + voucherDiscount;

        if (backendDiscount > parsedDiscount) {
          promoDiscount += backendDiscount - parsedDiscount;
        }
      }

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

  Future<void> applySelectedPromotion({
    required PromotionModel promotion,
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    // -----------------------------------------------------------------------
    // CEK PROMO MASIH VALID
    // -----------------------------------------------------------------------

    if (!promotion.isValidNow) {
      Get.snackbar(
        "Promo",
        "Promo ini sudah tidak aktif atau sudah melewati masa berlaku.",
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    // -----------------------------------------------------------------------
    // CEK DUPLIKAT
    // -----------------------------------------------------------------------

    if (promoCodes.contains(promotion.code)) {
      Get.snackbar(
        "Promo",
        "Promo ${promotion.name} sudah diterapkan.",
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    // -----------------------------------------------------------------------
    // CEK STACKABLE
    //
    // Promo hanya boleh digabung jika:
    //
    // 1. Promo yang sudah diterapkan semuanya stackable
    // 2. Promo baru juga stackable
    //
    // Kalau salah satu false -> tidak boleh digabung.
    // -----------------------------------------------------------------------

    if (promoCodes.isNotEmpty) {
      bool hasNonStackablePromo = false;

      for (final code in promoCodes) {
        final existingPromo = promotions.firstWhereOrNull(
          (promo) => promo.code == code,
        );

        if (existingPromo != null && !existingPromo.stackable) {
          hasNonStackablePromo = true;
          break;
        }
      }

      if (hasNonStackablePromo) {
        Get.snackbar(
          "Promo Tidak Bisa Digabung",
          "Promo yang sedang digunakan tidak dapat digabung dengan promo lain.",
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      if (!promotion.stackable) {
        Get.snackbar(
          "Promo Tidak Bisa Digabung",
          "Promo ${promotion.name} tidak dapat digabung dengan promo lain.",
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }
    }

    // -----------------------------------------------------------------------
    // SIMPAN PROMO LAMA
    // -----------------------------------------------------------------------

    final previousPromoCodes = [...promoCodes];

    // -----------------------------------------------------------------------
    // TAMBAHKAN PROMO BARU
    // -----------------------------------------------------------------------

    promoCodes.add(promotion.code);

    // Dropdown tidak perlu menyimpan item terakhir sebagai selected value.
    selectedPromotion.value = null;

    // -----------------------------------------------------------------------
    // PREVIEW ULANG KE BACKEND
    // -----------------------------------------------------------------------

    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );

    // -----------------------------------------------------------------------
    // INFO USER
    // -----------------------------------------------------------------------

    Get.snackbar(
      "Promo Berhasil",
      "${promotion.name} berhasil diterapkan.",
      snackPosition: SnackPosition.BOTTOM,
    );
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
      bool voucherApplied = false;

      for (final entry in appliedPromotions) {
        if (entry is! Map) continue;

        final type = (entry['discount_type'] ?? entry['type'] ?? '')
            .toString()
            .toLowerCase();

        final rewardType = (entry['reward_type'] ?? '')
            .toString()
            .toLowerCase();

        final amount =
            (entry['discount_amount'] as num?)?.toInt() ??
            (entry['amount'] as num?)?.toInt() ??
            0;

        if (type.contains('voucher')) {
          voucherApplied = true;
          voucherDiscount += amount;

          if (rewardType == "free_item") {
            print("Voucher Free Item berhasil diterapkan");
          }
        }
      }

      if (!voucherApplied) {
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
    if (!promoCodes.contains(code)) {
      return;
    }

    promoCodes.remove(code);

    // Reset dropdown
    selectedPromotion.value = null;

    // Hitung ulang diskon setelah promo dihapus
    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );

    Get.snackbar(
      "Promo Dibatalkan",
      "Promo $code berhasil dibatalkan.",
      snackPosition: SnackPosition.BOTTOM,
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
    loadPromotions();
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
  // LOAD PROMO
  // =========================================================================

  Future<void> loadPromotions() async {
    isLoading.value = true;

    try {
      promotions.value = await PromotionService.getPromotions();
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
        CacheService.clearProductCache();

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
        Get.to(() => PaymentWebViewPage(url: redirectUrl));

        _startStatusChecking(transactionId, result, showDialog: false);

        Get.snackbar(
          'Pembayaran',
          'Selesaikan pembayaran di dalam aplikasi melalui halaman pembayaran.',
        );
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

  void _startStatusChecking(
    String transactionId,
    Map<String, dynamic> data, {
    bool showDialog = true,
  }) {
    if (showDialog) {
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
    }

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
            _handleTimeout(transactionId, showDialog: showDialog);
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

          if (showDialog) {
            Get.back();
          }

          CacheService.clearProductCache();
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

          if (showDialog) {
            Get.back();
          }

          CacheService.clearProductCache();
          _showFailedDialog();

          return;
        }

        // ---------------------------------------------------------------
        // TIMEOUT
        // ---------------------------------------------------------------

        if (attempts >= maxAttempts) {
          _handleTimeout(transactionId, showDialog: showDialog);
        }
      } catch (e) {
        print("PAYMENT POLLING ERROR: $e");

        if (attempts >= maxAttempts) {
          _handleTimeout(transactionId, showDialog: showDialog);
        }
      }
    });
  }

  // =========================================================================
  // TIMEOUT
  // =========================================================================

  void _handleTimeout(String transactionId, {bool showDialog = true}) {
    _statusCheckTimer?.cancel();

    if (showDialog) {
      Get.back();
    }

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
