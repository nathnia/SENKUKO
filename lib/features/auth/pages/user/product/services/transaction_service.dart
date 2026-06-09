// lib/features/auth/pages/user/product/services/transaction_service.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev";

  // transaction_service.dart
  // lib/features/auth/pages/user/product/services/transaction_service.dart
  static Future<Map<String, dynamic>?> createTransaction({
    required List<dynamic> items,
    required String paymentMethod,
    required String address,
    required String city,
    required String region,
    required String subregion,
    String note = "",
  }) async {
    try {
      final box = GetStorage();
      final token = box.read("token");
      final user = box.read("user");

      print("========== DEBUG TRANSACTION ==========");
      print("TOKEN PRESENT: ${token != null}");
      print("USER DATA: $user");
      print("ITEMS COUNT: ${items.length}");
      print("PAYMENT METHOD: $paymentMethod");
      print("=======================================");

      // Validasi awal
      if (token == null) {
        print("ERROR: No authentication token");
        return null;
      }

      if (items.isEmpty) {
        print("ERROR: No items in cart");
        return null;
      }

      if (address.isEmpty || city.isEmpty || region.isEmpty) {
        print("ERROR: Delivery information incomplete");
        return null;
      }

      // Validasi setiap item
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print("VALIDATING ITEM $i:");

        if (item == null) {
          print("ERROR: Item $i is null");
          return null;
        }

        print("  Name: ${item.name ?? 'N/A'}");
        print("  Variant ID: ${item.variantId ?? 'N/A'}");
        print("  Price List ID: ${item.priceListId ?? 'N/A'}");
        print("  Qty: ${item.qty ?? 'N/A'}");

        // Validasi field yang diperlukan
        if (item.variantId == null || item.variantId.toString().isEmpty) {
          print("ERROR: Item $i missing variantId");
          return null;
        }

        if (item.priceListId == null || item.priceListId.toString().isEmpty) {
          print("ERROR: Item $i missing priceListId");
          return null;
        }

        if (item.qty == null || item.qty <= 0) {
          print("ERROR: Item $i invalid qty: ${item.qty}");
          return null;
        }
      }

      // Pastikan priceListId dari item pertama
      final priceListId = items.first.priceListId;
      if (priceListId == null) {
        print("ERROR: First item missing priceListId");
        return null;
      }

      final body = {
        "price_list_id": priceListId.toString(),
        "payment_method": paymentMethod.toLowerCase(),
        "delivery_address": address.trim(),
        "delivery_city": city.trim(),
        "delivery_region": region.trim(),
        "delivery_subregion": subregion.trim(),
        "delivery_note": note.trim(),
        "items": items.map((e) {
          return {"product_variant_id": e.variantId.toString(), "qty": e.qty};
        }).toList(),
      };

      print("========== REQUEST BODY ==========");
      print(json.encode(body));
      print("=================================");

      final response = await http.post(
        Uri.parse("$baseUrl/api/transactions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      print("========== RESPONSE ==========");
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("==============================");

      // Handle berbagai status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data["success"] == true) {
          print("TRANSACTION CREATED SUCCESSFULLY");
          print("DATA: ${data["data"]}");
          return data["data"] as Map<String, dynamic>?;
        } else {
          print("API ERROR: ${data["message"] ?? "Unknown API error"}");
          return null;
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        print("BAD REQUEST: ${errorData["message"] ?? response.body}");
        return null;
      } else if (response.statusCode == 401) {
        print("UNAUTHORIZED: Token invalid or expired");
        return null;
      } else if (response.statusCode == 500) {
        print("SERVER ERROR: Internal server error");
        return null;
      } else {
        print("UNEXPECTED STATUS: ${response.statusCode}");
        print("RESPONSE: ${response.body}");
        return null;
      }
    } catch (e, stackTrace) {
      print("========== FATAL ERROR ==========");
      print("ERROR TYPE: ${e.runtimeType}");
      print("ERROR MESSAGE: $e");
      print("STACK TRACE: $stackTrace");
      print("===============================");
      return null;
    }
  }

static Future<Map<String, dynamic>?> checkPaymentStatus(
  String transactionId,
) async {
  try {
    final box = GetStorage();
    final token = box.read("token");

    final response = await http.get(
      Uri.parse("$baseUrl/api/transactions/$transactionId/check-payment"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("Check payment response: ${response.statusCode}");
    print("Check payment body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["success"] == true) return data["data"];
    }
    return null;
  } catch (e) {
    print("Check payment error: $e");
    return null;
  }
}
// TAMBAHKAN DI TransactionService:
static Future<Map<String, dynamic>?> checkTransactionStatus(
  String transactionId,
) async {
  try {
    final box = GetStorage();
    final token = box.read("token");

    if (token == null) {
      print("No token available");
      return null;
    }

    print("Checking status for transaction: $transactionId");

    final response = await http.get(
      Uri.parse("$baseUrl/api/transactions/$transactionId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("Status check response: ${response.statusCode}");
    print("Status check body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["success"] == true) {
        return data["data"];
      }
    }

    return null;
  } catch (e) {
    print("Check status error: $e");
    return null;
  }
}
  // DETAIL TRANSACTION
  // GET /api/transactions/:id
  static Future<Map<String, dynamic>?> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read("token");

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/$transactionId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("========== DETAIL TRANSACTION ==========");
      print("STATUS = ${response.statusCode}");
      print("BODY = ${response.body}");
      print("=======================================");

      if (response.statusCode == 200 || response.statusCode == 201) {
  try {
    final data = json.decode(response.body);
    print("DECODED DATA: $data");
    print("DATA TYPE: ${data.runtimeType}");
    
    if (data is Map<String, dynamic> && data["success"] == true) {
      final result = data["data"];
      print("RESULT: $result");
      print("RESULT TYPE: ${result.runtimeType}");
      return result as Map<String, dynamic>?;
    }
  } catch (decodeErr) {
    print("DECODE ERROR: $decodeErr");
    return null;
  }
}

      return null;
    } catch (e) {
      print("ERROR DETAIL TRANSACTION:");
      print(e);
      return null;
    }
  }

  // CREATE TRANSACTION
  // POST /api/transactions
}
