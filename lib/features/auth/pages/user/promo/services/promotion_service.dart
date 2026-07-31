import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:senkuko/features/auth/pages/user/service.user/cache_service.dart';
import '../models/promotion_model.dart';

class PromotionService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  static Future<List<PromotionModel>> getPromotions() async {
    try {
      // ================= CACHE =================
      if (!CacheService.isExpired(CacheService.promotionTime)) {
        final cache = CacheService.read(CacheService.promotionKey);

        if (cache != null) {
          print("📦 PROMOTION FROM CACHE");

          return (cache as List)
              .map((e) => PromotionModel.fromJson(e))
              .toList();
        }
      }

      print("🌐 PROMOTION FROM API");

      final response = await http.get(
        Uri.parse("$baseUrl/api/promotions"),
        headers: {
          "Accept": "application/json",
        },
      );

      print("=== PROMOTION STATUS ===");
      print(response.statusCode);

      print("=== PROMOTION BODY ===");
      print(response.body);

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      final List data = json["data"] ?? [];

      // ================= SAVE CACHE =================
      CacheService.save(
        CacheService.promotionKey,
        data,
      );

      CacheService.saveTime(
        CacheService.promotionTime,
      );

      print("TOTAL PROMOTION : ${data.length}");

      return data
          .map((e) => PromotionModel.fromJson(e))
          .toList();
    } catch (e) {
      print("PROMOTION ERROR : $e");
      return [];
    }
  }
}