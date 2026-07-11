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

        final candidates = <dynamic>[];
        final entries = data['data'];
        if (entries is List) {
          candidates.addAll(entries);
        } else if (entries is Map) {
          candidates.add(entries);
        }

        for (final candidate in candidates) {
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate;
          }
          if (candidate is Map) {
            final url = candidate['image_url'] ??
                candidate['imageUrl'] ??
                candidate['url'] ??
                candidate['src'] ??
                candidate['image'] ??
                candidate['thumbnail'];
            if (url != null && url.toString().trim().isNotEmpty) {
              return url.toString();
            }
          }
        }

        final direct = data['image_url'] ??
            data['imageUrl'] ??
            data['url'] ??
            data['src'] ??
            data['image'] ??
            data['thumbnail'];
        if (direct != null && direct.toString().trim().isNotEmpty) {
          return direct.toString();
        }
      }
    } catch (e) {
      print("ERROR IMAGE: $e");
    }

    return null;
  }
}