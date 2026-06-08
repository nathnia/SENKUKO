import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev";

  // HISTORY TRANSACTION CUSTOMER
  // GET /api/transactions/history
  static Future<List<dynamic>> getTransactions() async {
    try {
      final box = GetStorage();
      final token = box.read("token");

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/history"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("🔥 HISTORY STATUS: ${response.statusCode}");
      print("🔥 HISTORY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          return data["data"] ?? [];
        }
      }

      return [];
    } catch (e) {
      print("🔥 ERROR HISTORY:");
      print(e);
      return [];
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          return data["data"];
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
      print("TOKEN TYPE = ${token.runtimeType}");
      print("TOKEN VALUE = $token");
      print("USER DATA = $user");
      print("AUTH HEADER = Bearer $token");
      print("======================================");

      print("========== ITEM DEBUG ==========");

      for (final item in items) {
        print(
          "NAME=${item.name}"
          " | VARIANT=${item.variantId}"
          " | PRICE_LIST=${item.priceListId}"
          " | QTY=${item.qty}",
        );
      }

      print("===============================");

      final body = {
        "price_list_id": items.first.priceListId,
        "payment_method": paymentMethod.toLowerCase(),
        "delivery_address": address,
        "delivery_city": city,
        "delivery_region": region,
        "delivery_subregion": subregion,
        "delivery_note": note,
        "items": items.map((e) {
          return {
            "product_variant_id": e.variantId,
            "qty": e.qty,
          };
        }).toList(),
      };

      for (final item in items) {
        print(
          "ITEM => ${item.name}"
          " | VARIANT=${item.variantId}"
          " | PRICE_LIST=${item.priceListId}"
          " | QTY=${item.qty}",
        );
      }

      print("REQUEST BODY:");
      print(json.encode(body));

      final response = await http.post(
        Uri.parse("$baseUrl/api/transactions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      print("========== RESPONSE ==========");
      print("STATUS CODE = ${response.statusCode}");
      print("BODY = ${response.body}");
      print("==============================");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data["success"] == true) {
          return data["data"];
        }
      }

      return null;
    } catch (e) {
      print("ERROR CREATE TRANSACTION:");
      print(e);
      return null;
    }
  }
}