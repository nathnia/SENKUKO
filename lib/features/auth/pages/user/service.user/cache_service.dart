import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class CacheService {
  static final box = GetStorage();

  static const productKey = "cache_products";
  static const bannerKey = "cache_banners";
  static const promotionKey = "cache_promotions";

  static const productTime = "cache_products_time";
  static const bannerTime = "cache_banners_time";
  static const promotionTime = "cache_promotions_time";

  static const duration = Duration(minutes: 10);

  static bool isExpired(String key) {
    final time = box.read(key);

    if (time == null) return true;

    final last = DateTime.parse(time);

    return DateTime.now().difference(last) > duration;
  }

  static void save(String key, dynamic data) {
    box.write(key, jsonEncode(data));
  }

  static dynamic read(String key) {
    final raw = box.read(key);

    if (raw == null) return null;

    return jsonDecode(raw);
  }

  static void saveTime(String key) {
    box.write(key, DateTime.now().toIso8601String());
  }

  static void clearAll() {
    box.remove(productKey);
    box.remove(productTime);  

    box.remove(bannerKey);
    box.remove(bannerTime);

    box.remove(promotionKey);
    box.remove(promotionTime);
  }
}