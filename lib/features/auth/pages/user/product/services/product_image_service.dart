import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductImageService {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api";

  static Future<String?> getProductImage(String productId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/products/$productId/images"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // asumsi backend return list images
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0]['image_url']; // ambil image pertama
        }
      }
    } catch (e) {
      print("ERROR IMAGE: $e");
    }

    return null;
  }
}