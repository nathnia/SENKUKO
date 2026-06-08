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

      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          return data["data"];
        }
      }

      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }
}