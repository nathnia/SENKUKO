// lib/features/auth/pages/user/product/services/transaction_service.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ---------------------------------------------------------------------------
/// Service yang berkomunikasi dengan endpoint `/api/transactions`.
/// ---------------------------------------------------------------------------
class TransactionService {
  static final String baseUrl =
      dotenv.env['BASE_URL']!;

  // -------------------------------------------------------------------------
  // 2️⃣  CREATE / PREVIEW TRANSACTION
  // -------------------------------------------------------------------------
  /// `previewOnly` = true → backend hanya menghitung potongan & mengembalikan
  /// `grand_total`, `applied_promotions`, dsb. (tidak menyimpan transaksi).
  ///
  /// `priceListId` = optional, bila UI Anda meng‑select satu price‑list.
  ///
  /// `promoCodes` / `voucherCodes` dapat dikirim secara list ataupun
  /// “single code” (promoCode / voucherCode). Semua kode di‑upper‑case
  /// sebelum dikirim ke server.
  static Future<Map<String, dynamic>?> createTransaction({
    // -----------------------------------------------------------------------
    // 2.1  Data barang & pembayaran
    // -----------------------------------------------------------------------
    required List<dynamic> items,
    required String paymentMethod,
    required String address,
    required String city,
    required String region,
    required String subregion,
    String note = "",

    // -----------------------------------------------------------------------
    // 2.2  Kode promo / voucher (bisa satu atau banyak)
    // -----------------------------------------------------------------------
    String? promoCode,
    String? voucherCode,
    List<String> promoCodes = const [],
    List<String> voucherCodes = const [],

    // -----------------------------------------------------------------------
    // 2.3  Price‑list (opsional)
    // -----------------------------------------------------------------------
    String? priceListId,

    // -----------------------------------------------------------------------
    // 2.4  Preview flag
    // -----------------------------------------------------------------------
    bool previewOnly = false,
  }) async {
    try {
      // ---------------------------------------------------------------------
      // 2.5  Ambil token + data user (debug)
      // ---------------------------------------------------------------------
      final box = GetStorage();
      final token = box.read("token");
      final user = box.read("user");

      print("=== CREATE TRANSACTION DEBUG ===");
      print("TOKEN   : ${token != null}");
      print("USER    : $user");
      print("ITEMS   : ${items.length}");
      print("PAYMENT : $paymentMethod");
      print("PREVIEW : $previewOnly");
      print("===============================");

      // ---------------------------------------------------------------------
      // 2.6  Validasi dasar
      // ---------------------------------------------------------------------
      if (token == null) {
        print("❌ ERROR: No authentication token");
        return null;
      }
      if (items.isEmpty) {
        print("❌ ERROR: Cart is empty");
        return null;
      }
      if (address.isEmpty || city.isEmpty || region.isEmpty) {
        print("❌ ERROR: Delivery info incomplete");
        return null;
      }

      // ---------------------------------------------------------------------
      // 2.7  Normalisasi semua kode ke Upper‑Case & hapus duplikat
      // ---------------------------------------------------------------------
      final Set<String> effectivePromo = {};
      if (promoCode != null && promoCode.trim().isNotEmpty) {
        for (final code in promoCode.split(RegExp(r'[\s,;]+'))) {
          final trimmed = code.trim();
          if (trimmed.isNotEmpty) effectivePromo.add(trimmed.toUpperCase());
        }
      }
      for (final c in promoCodes) {
        if (c.trim().isNotEmpty) effectivePromo.add(c.trim().toUpperCase());
      }

      final Set<String> effectiveVoucher = {};
      if (voucherCode != null && voucherCode.trim().isNotEmpty) {
        for (final code in voucherCode.split(RegExp(r'[\s,;]+'))) {
          final trimmed = code.trim();
          if (trimmed.isNotEmpty) effectiveVoucher.add(trimmed.toUpperCase());
        }
      }
      for (final c in voucherCodes) {
        if (c.trim().isNotEmpty) effectiveVoucher.add(c.trim().toUpperCase());
      }

      // ---------------------------------------------------------------------
      // 2.8  Build payload `items`
      // ---------------------------------------------------------------------
      // Backend (berdasarkan contoh Anda) mengharapkan:
      //   { "product_variant_id": "...", "qty": 2, "price_list_id": "..." }
      // price_list_id per‑item *bisa* di‑abaikan bila tidak ada.
      final List<Map<String, dynamic>> itemsPayload = items.map((e) {
        return {
          "product_variant_id": e.variantId?.toString() ?? '',
          "qty": e.qty ?? 0,
          // price_list_id per‑item (optional – jika null akan di‑ignore)
          if (e.priceListId != null && e.priceListId.toString().isNotEmpty)
            "price_list_id": e.priceListId.toString(),
        };
      }).toList();

      String? resolvedPriceListId = priceListId;
      final itemPriceListIds = itemsPayload
          .map((e) => e["price_list_id"] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet();

      if ((resolvedPriceListId == null || resolvedPriceListId.isEmpty) &&
          itemPriceListIds.length == 1) {
        resolvedPriceListId = itemPriceListIds.first;
      }

      // ---------------------------------------------------------------------
      // 2.9  Assemble final body
      // ---------------------------------------------------------------------
      final Map<String, dynamic> body = {
        // root price_list_id (jika Anda punya satu price‑list untuk seluruh
        // transaksi). Jika null, backend biasanya meng‑ignore field ini.
        if (resolvedPriceListId != null && resolvedPriceListId.isNotEmpty)
          "price_list_id": resolvedPriceListId,
        "payment_method": paymentMethod.toLowerCase(),
        "delivery_address": address.trim(),
        "delivery_city": city.trim(),
        "delivery_region": region.trim(),
        "delivery_subregion": subregion.trim(),
        "delivery_note": note.trim(),
        "items": itemsPayload,
        "promo_codes": effectivePromo.toList(),
        "voucher_codes": effectiveVoucher.toList(),
        // penting! flag preview
        "preview_only": previewOnly,
      };

      print("=== REQUEST BODY ===");
      print(json.encode(body));
      print("====================");

      // ---------------------------------------------------------------------
      // 2.10  Kirim request
      // ---------------------------------------------------------------------
      final response = await http.post(
        Uri.parse("$baseUrl/api/transactions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      // ---------------------------------------------------------------------
      // 2.11  Logging response
      // ---------------------------------------------------------------------
      print("=== RESPONSE ===");
      print("Status code : ${response.statusCode}");
      print("Body        : ${response.body}");
      print("=================");

      // ---------------------------------------------------------------------
      // 2.12  Parse response (berdasarkan struktur API Anda)
      // ---------------------------------------------------------------------
      // API yang Anda tunjukkan mengembalikan:
      //   { "success": true, "data": { ... } }
      // Jika `success` false atau kode selain 2xx → dianggap error.
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded["success"] == true) {
          // data dapat berupa Map atau List – dalam kasus checkout biasanya Map
          final dynamic data = decoded["data"];
          if (data is Map<String, dynamic>) {
            return data;
          } else {
            // fallback bila API mengembalikan list (mis: preview list)
            return {"data": data};
          }
        } else {
          // API mengembalikan error message di dalam field `message`
          print("API ERROR: ${decoded["message"] ?? "Tidak diketahui"}");
          return null;
        }
      }

      // ---------------------------------------------------------------------
      // 2.13  Penanganan kode error khusus
      // ---------------------------------------------------------------------
      if (response.statusCode == 400) {
        final err = json.decode(response.body);
        print("❌ BAD REQUEST: ${err["message"] ?? response.body}");
        return null;
      }
      if (response.statusCode == 401) {
        print("❌ UNAUTHORIZED: Token invalid/expired");
        return null;
      }
      if (response.statusCode >= 500) {
        print("❌ SERVER ERROR (${response.statusCode})");
        return null;
      }

      // ---------------------------------------------------------------------
      // 2.14  Default fallback
      // ---------------------------------------------------------------------
      print("❌ UNEXPECTED STATUS: ${response.statusCode}");
      return null;
    } catch (e, stack) {
      print("=== FATAL ERROR IN createTransaction ===");
      print("TYPE    : ${e.runtimeType}");
      print("MESSAGE : $e");
      print("STACK   : $stack");
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 3️⃣  CEK STATUS PEMBAYARAN (midtrans / payment gateway lain)
  // -------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> checkPaymentStatus(
    String transactionId,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read("token");
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/$transactionId/check-payment"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("=== CHECK PAYMENT STATUS ===");
      print("Status : ${response.statusCode}");
      print("Body   : ${response.body}");
      print("============================");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded["success"] == true) {
          return decoded["data"] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print("⚠️ checkPaymentStatus error: $e");
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 4️⃣  CEK STATUS TRANSAKSI (digunakan di polling setelah redirect)
  // -------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> checkTransactionStatus(
    String transactionId,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read("token");
      if (token == null) {
        print("⚠️ No token for checkTransactionStatus");
        return null;
      }

      print("🔎 Checking transaction status for ID: $transactionId");

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/$transactionId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("=== TRANSACTION STATUS RESPONSE ===");
      print("Status : ${response.statusCode}");
      print("Body   : ${response.body}");
      print("==============================");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded["success"] == true) {
          return decoded["data"] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print("⚠️ checkTransactionStatus error: $e");
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 5️⃣  DETAIL TRANSAKSI (GET /api/transactions/:id)
  // -------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read("token");
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/$transactionId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("=== GET TRANSACTION DETAIL ===");
      print("Status : ${response.statusCode}");
      print("Body   : ${response.body}");
      print("==============================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded["success"] == true) {
          return decoded["data"] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print("⚠️ getTransactionDetail error: $e");
      return null;
    }
  }

  
}