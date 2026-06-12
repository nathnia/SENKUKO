import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class HistoryService {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev";

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
}