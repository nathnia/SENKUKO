import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CategoryService {
  static final String baseUrl =
      dotenv.env['BASE_URL']!;

  static Future<List<Category>> getCategories() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/categories'),
              headers: {"Accept": "application/json"})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 &&
          res.body.trim().startsWith('{')) {
        final json = jsonDecode(res.body);
        final data = json['data'] is List ? json['data'] : [];

        return data.map<Category>((e) {
          return Category(
            id: e['id'].toString(),
            name: e['name'] ?? e['category_name'] ?? '',
          );
        }).toList();
      }

      print("CATEGORY API ERROR");
    } catch (e) {
      print("CATEGORY ERROR: $e");
    }

    //FALLBACK (biar ga loading terus)
    return [
      Category(id: "0", name: "Semua"),
      Category(id: "1", name: "Makanan & Minuman"),
      Category(id: "2", name: "Produk Bayi"),
      Category(id: "3", name: "Alat Tulis Kantor"),
      Category(id: "4", name: "Rumah Tangga"),
      Category(id: "5", name: "Perawatan Diri"),
      Category(id: "6", name: "Sembako"),
      Category(id: "7", name: "UMKM"),
    ];
  }
}