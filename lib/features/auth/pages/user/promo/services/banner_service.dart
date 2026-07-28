import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

class BannerService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  static Future<List<BannerModel>> getActiveBanner() async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/api/banners/active"),
      headers: {
        "Accept": "application/json",
      },
    );

    print("=== BANNER STATUS ===");
    print(response.statusCode);

    print("=== BANNER BODY ===");
    print(response.body);

    if (response.statusCode != 200) {
      return [];
    }

    final json = jsonDecode(response.body);

    final List data = json["data"];

    print("TOTAL BANNER : ${data.length}");

    return data.map((e) => BannerModel.fromJson(e)).toList();
  } catch (e) {
    print("BANNER ERROR : $e");
    return [];
  }
}
}