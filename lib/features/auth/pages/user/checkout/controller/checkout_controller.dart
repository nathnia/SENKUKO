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
  // -------------------------------------------------------------------------
  // 1️⃣  Dependensi & storage
  // -------------------------------------------------------------------------
  late final CartController cart = Get.find<CartController>();
  late final GetStorage box = GetStorage();

  // -------------------------------------------------------------------------
  // 2️⃣  Form field
  // -------------------------------------------------------------------------
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final regionController = TextEditingController();
  final subregionController = TextEditingController();
  final noteController = TextEditingController();
  final promoController = TextEditingController();
  final voucherController = TextEditingController();

  // -------------------------------------------------------------------------
  // 3️⃣  Reactive state
  // -------------------------------------------------------------------------
  final isEditingAddress = false.obs;
  final paymentMethod = "cod".obs;                      // cod, bank_transfer, gopay, shopeepay
  final isLoading = false.obs;                         // loading preview / checkout
  final methods = [
    {"label": "COD", "value": "cod"},
    {"label": "Transfer Bank", "value": "bank_transfer"},
    {"label": "GoPay", "value": "gopay"},
    {"label": "ShopeePay", "value": "shopeepay"},
  ].obs;

  // Kode yang sudah dipilih
  final promoCodes = <String>[].obs;
  final voucherCodes = <String>[].obs;

  // Nilai yang didapatkan dari *preview* backend
  final promoDiscountAmount = 0.obs;   // total potongan promo
  final voucherDiscountAmount = 0.obs; // total potongan voucher
  final totalPrice = 0.obs;            // grand_total yang dikembalikan server
  final discount = 0.obs;             // promo + voucher (convenient)

  // -------------------------------------------------------------------------
  // 4️⃣  Helper kalkulasi diskon (untuk preview / test)
  // -------------------------------------------------------------------------
  static int calculateDiscountAmount(String code, int subtotal) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || subtotal <= 0) return 0;

    final match = RegExp(r'(\d+)$').firstMatch(normalized);
    if (match == null) return 0;

    final percent = int.tryParse(match.group(1) ?? '') ?? 0;
    if (percent <= 0) return 0;

    final isPromoCode = normalized.startsWith('PROMO');
    final isVoucherCode = normalized.startsWith('VOUCHER');
    if (!isPromoCode && !isVoucherCode) return 0;

    return ((subtotal * percent) / 100).round();
  }

  static int calculateDiscountTotal(List<String> codes, int subtotal) {
    return codes.fold<int>(0, (sum, code) => sum + calculateDiscountAmount(code, subtotal));
  }

  // -------------------------------------------------------------------------
  // 5️⃣  (Optional) Price‑list yang dipilih pada UI
  // -------------------------------------------------------------------------
  // Jika aplikasi Anda tidak memakai konsep price‑list, cukup biarkan null.
  final RxString? selectedPriceListId = RxString('');

  // -------------------------------------------------------------------------
  // 6️⃣  Timer untuk polling status pembayaran (Midtrans)
  // -------------------------------------------------------------------------
  Timer? _statusCheckTimer;

  void changeMethod(String? method) {
    if (method == null || method.isEmpty) return;
    paymentMethod.value = method;
  }

  // -------------------------------------------------------------------------
  // 6️⃣  Helper – meng‑extract variant‑id dari model CartItem Anda
  // -------------------------------------------------------------------------
  String? _resolveVariantId(dynamic item) {
    // Sesuaikan dengan properti yang ada di class CartItem Anda.
    // Contoh umum: item.variantId, item.productVariantId, atau item.id
    try {
      return item.variantId?.toString() ??
          item.productVariantId?.toString() ??
          item.id?.toString();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 7️⃣  PREVIEW DISCOUNT (dipanggil setiap kali kode berubah atau subtotal
  //     berubah)
  // -------------------------------------------------------------------------
  Future<void> previewDiscounts({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId, // optional – bila UI memakai price‑list
  }) async {
    if (items.isEmpty) {
      promoDiscountAmount.value = 0;
      voucherDiscountAmount.value = 0;
      totalPrice.value = subtotal;
      discount.value = 0;
      return;
    }

    // Build payload `items` yang diminta backend
    final List<Map<String, dynamic>> mappedItems = [];
    for (final it in items) {
      final variantId = _resolveVariantId(it);
      if (variantId != null && variantId.isNotEmpty) {
        mappedItems.add({
          "product_variant_id": variantId,
          "qty": it.qty,
          // jika setiap item memiliki price_list_id, sertakan di sini
          if (it.priceListId != null && it.priceListId.toString().isNotEmpty)
            "price_list_id": it.priceListId.toString(),
        });
      }
    }

    if (mappedItems.isEmpty) {
      // tidak ada variant yang dapat dipetakan → tidak ada potongan
      promoDiscountAmount.value = 0;
      voucherDiscountAmount.value = 0;
      totalPrice.value = subtotal;
      discount.value = 0;
      return;
    }

    isLoading.value = true;

    try {
      final response = await TransactionService.createTransaction(
        items: items, // service sendiri akan membuat `itemsPayload` lagi,
        // jadi tidak dipakai di sini, tapi kami tetap meng‑pass untuk
        // validasi internal service (jika service mem‑check variantId).
        paymentMethod: paymentMethod.value,
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        region: regionController.text.trim(),
        subregion: subregionController.text.trim(),
        note: noteController.text.trim(),
        promoCodes: promoCodes.toList(),
        voucherCodes: voucherCodes.toList(),
        priceListId: priceListId,
        previewOnly: true, // <‑‑ KUNCI UTAMA
      );

      if (response == null) throw Exception('Response null');

      // Backend Anda biasanya mengembalikan:
      //   { "data": { "applied_promotions": [...], "grand_total": ... } }
      final data = response['data'] ?? response;

      // ------------------- Ambil promo & voucher yang berhasil -------------------
      final List applied = (data['applied_promotions'] as List?) ?? [];

      int promo = 0;
      int voucher = 0;
      for (final entry in applied) {
        final type = (entry['discount_type'] ?? 'promo').toString().toLowerCase();
        final amount = (entry['discount_amount'] as num?)?.toInt() ?? 0;
        if (type == 'voucher') {
          voucher += amount;
        } else {
          promo += amount;
        }
      }

      // ------------------- Grand total -------------------
      final int grand = (data['grand_total'] as num?)?.toInt() ??
          (subtotal - promo - voucher);

      // ------------------- Simpan ke reactive variable -------------------
      promoDiscountAmount.value = promo;
      voucherDiscountAmount.value = voucher;
      discount.value = promo + voucher;
      totalPrice.value = grand;
    } catch (e) {
      // Jika ada error (mis. kode tidak valid) → reset ke nilai tanpa potongan
      promoDiscountAmount.value = 0;
      voucherDiscountAmount.value = 0;
      discount.value = 0;
      totalPrice.value = subtotal;

      Get.snackbar('Preview Gagal', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------------------------
  // 8️⃣  PUBLIC API – dipanggil UI (add / remove kode)
  // -------------------------------------------------------------------------
  Future<void> applyPromo({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    final code = promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (!promoCodes.contains(code)) promoCodes.add(code);
    promoController.clear();

    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );
  }

  Future<void> applyVoucher({
    required int subtotal,
    required List<dynamic> items,
    String? priceListId,
  }) async {
    final code = voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (!voucherCodes.contains(code)) voucherCodes.add(code);
    voucherController.clear();

    await previewDiscounts(
      subtotal: subtotal,
      items: items,
      priceListId: priceListId,
    );
  }

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

  // -------------------------------------------------------------------------
  // 9️⃣  Load profile (tidak berubah)
  // -------------------------------------------------------------------------
  void syncProfileToControllers(Map<String, dynamic>? user) {
    if (user == null) return;

    addressController.text = (user["address"] ?? "").toString();
    cityController.text = (user["city"] ?? "").toString();
    regionController.text = (user["region"] ?? "").toString();
    subregionController.text = (user["subregion"] ?? "").toString();
  }

  @override
  void onInit() {
    super.onInit();
    final savedUser = box.read("user");
    if (savedUser is Map) {
      syncProfileToControllers(Map<String, dynamic>.from(savedUser));
    }
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    final user = await AuthService.getProfile();
    if (user != null) {
      syncProfileToControllers(user);
      await box.write("user", user);
    }
    isLoading.value = false;
  }

  // -------------------------------------------------------------------------
  // 10️⃣  Checkout (tanpa preview_only)
  // -------------------------------------------------------------------------
  Future<void> checkout({
    required bool fromCart,
    required List<dynamic> items,
    String? promoCode,
    String? voucherCode,
    String? priceListId,
  }) async {
    // ------------------- Validasi alamat -------------------
    if (cityController.text.trim().isEmpty ||
        regionController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Lengkapi data alamat pengiriman');
      return;
    }

    isLoading.value = true;

    try {
      // Jika user men‑press tombol Bayar tanpa men‑add kode lewat UI,
      // gunakan kode yang di‑type pada TextField (jika ada)
      final List<String> promoList = promoCodes.isNotEmpty
          ? promoCodes.toList()
          : (promoCode?.isNotEmpty == true
              ? [promoCode!.toUpperCase()]
              : []);
      final List<String> voucherList = voucherCodes.isNotEmpty
          ? voucherCodes.toList()
          : (voucherCode?.isNotEmpty == true
              ? [voucherCode!.toUpperCase()]
              : []);

      final result = await TransactionService.createTransaction(
        items: items,
        paymentMethod: paymentMethod.value,
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        region: regionController.text.trim(),
        subregion: subregionController.text.trim(),
        note: noteController.text.trim(),
        promoCodes: promoList,
        voucherCodes: voucherList,
        priceListId: priceListId,
        previewOnly: false,
      );

      if (result == null) throw Exception('null result');

      // ------------------- Hapus item dari cart (jika datang dari keranjang) -------------------
      if (fromCart) cart.removeSelectedItems();

      // ------------------- COD -------------------------------------------------
      if (result["payment_method"] == "cod") {
        Get.offAllNamed("/order-success", arguments: {
          "invoice": result["invoice_number"],
          "total": result["grand_total"],
          "status": result["status"] ?? "pending",
          "transaction_id": result["transaction_id"],
        });
        return;
      }

      // ------------------- PAYMENT GATEWAY (Midtrans, dsb) -----------------
      final String? redirectUrl = result["redirect_url"] as String?;
      final String? transactionId = (result["transaction_id"] ??
              result["id"])
          ?.toString();

      if (redirectUrl != null && transactionId != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _showPaymentDialog(transactionId, result);
        } else {
          Get.snackbar('Error', 'Tidak dapat membuka halaman pembayaran');
        }
      } else {
        Get.snackbar('Error', 'Data pembayaran tidak lengkap');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------------------------
  // 11️⃣  UI Helper: Dialog + polling status pembayaran
  // -------------------------------------------------------------------------
  void _showPaymentDialog(String transactionId, Map<String, dynamic> data) {
    // Langsung mulai polling; user tidak perlu men‑klik lagi.
    _startStatusChecking(transactionId, data);
  }

  /// Polling status setiap 3 detik, maksimal 20 x (≈ 60 detik)
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
            "Selesaikan pembayaran di aplikasi/browser.\nStatus akan otomatis diperbarui.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
      // tombol “Cek nanti” – hanya menutup dialog
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
    const maxAttempts = 20; // 20 × 3 detik = 60 detik

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      attempts++;

      try {
        final statusResult =
            await TransactionService.checkPaymentStatus(transactionId);

        if (statusResult == null) {
          if (attempts >= maxAttempts) _handleTimeout(transactionId);
          return;
        }

        final String? paymentStatus = (statusResult["payment_status"] ??
                statusResult["status"])
            .toString()
            .toLowerCase();

        // ----------- PAYMENT SUCCESS ------------
        if (paymentStatus == "paid") {
          _statusCheckTimer?.cancel();
          Get.back(); // tutup dialog waiting
          _showSuccessDialog(data);
          return;
        }

        // ----------- PAYMENT FAILED / CANCELED ------------
        if (paymentStatus == "cancel" ||
            paymentStatus == "expire" ||
            paymentStatus == "failed") {
          _statusCheckTimer?.cancel();
          Get.back();
          _showFailedDialog();
          return;
        }

        // ----------- STILL PENDING ------------
        if (attempts >= maxAttempts) _handleTimeout(transactionId);
      } catch (e) {
        if (attempts >= maxAttempts) _handleTimeout(transactionId);
      }
    });
  }

  void _handleTimeout(String transactionId) {
    _statusCheckTimer?.cancel();
    Get.back(); // tutup dialog waiting
    _showTimeoutDialog(transactionId);
  }

  void _showSuccessDialog(Map<String, dynamic> transactionData) {
    Get.defaultDialog(
      title: "Pembayaran Berhasil!",
      middleText:
          "Pembayaran Anda berhasil diproses.\n\nInvoice: ${transactionData["invoice_number"] ?? "-"}\nTotal: Rp ${transactionData["grand_total"] ?? 0}",
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
      middleText:
          "Pembayaran Anda gagal atau dibatalkan. Silakan coba lagi atau lihat riwayat pesanan.",
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
          "Pengecekan status pembayaran telah berakhir. Silakan cek manual di halaman Riwayat Pesanan.",
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

  // -------------------------------------------------------------------------
  // 12️⃣  Cleanup (dispose)
  // -------------------------------------------------------------------------
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