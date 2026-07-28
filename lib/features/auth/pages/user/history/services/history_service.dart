import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HistoryService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  static Future<List<dynamic>> getHistory() async {
    try {
      final token = GetStorage().read("token");

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/history"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("========== HISTORY RESPONSE ==========");
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("=====================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          final List transactions = data["data"] ?? [];

          // Debug: Print structure of first transaction
          if (transactions.isNotEmpty) {
            print("FIRST TRANSACTION STRUCTURE:");
            print(transactions[0]);

            // Debug tipe data
            transactions[0].forEach((key, value) {
              print("$key: ${value.runtimeType} = $value");
            });
          }

          return transactions;
        }
      }

      return [];
    } catch (e, stackTrace) {
      print("HISTORY SERVICE ERROR:");
      print(e);
      print("STACK TRACE:");
      print(stackTrace);
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTransactionDetail(String id) async {
    try {
      final token = GetStorage().read("token");

      print("========== GET DETAIL ==========");
      print("ID = $id");
      print("URL = $baseUrl/api/transactions/$id");

      final response = await http.get(
        Uri.parse("$baseUrl/api/transactions/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STATUS = ${response.statusCode}");
      print("BODY = ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          return data["data"];
        }
      }

      return null;
    } catch (e) {
      print("DETAIL ERROR = $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> cancelTransaction(
    String transactionId,
  ) async {
    try {
      final token = GetStorage().read("token");

      if (token == null) {
        print("❌ CANCEL ERROR: Token tidak ditemukan");
        return null;
      }

      final url = "$baseUrl/api/transactions/$transactionId/cancel";

      print("========== CANCEL TRANSACTION ==========");
      print("ID  : $transactionId");
      print("URL : $url");

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");
      print("=========================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return data["data"];
      }

      print(
        "❌ CANCEL FAILED: "
        "${data["message"] ?? "Gagal membatalkan transaksi"}",
      );

      return null;
    } catch (e, stackTrace) {
      print("❌ CANCEL TRANSACTION ERROR:");
      print(e);
      print(stackTrace);

      return null;
    }
  }
}
