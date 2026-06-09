import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_ui_model.dart';

class ProductCombinedService {
  static const baseUrl =
      'https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api';

  static Future<List> getAllProducts() async {
    try {
      final productRes = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {"Accept": "application/json"},
      );

      final priceRes = await http.get(
        Uri.parse('$baseUrl/product-prices'),
        headers: {"Accept": "application/json"},
      );

      if (productRes.statusCode != 200 || priceRes.statusCode != 200) {
        print("❌ API ERROR");
        return [];
      }

      final productJson = jsonDecode(productRes.body);
      final priceJson = jsonDecode(priceRes.body);

      final List products = productJson['data'] ?? [];
      final List prices = priceJson['data'] ?? [];

      print("========== PRICE DEBUG ==========");
      print(jsonEncode(prices.take(10).toList()));
      print("================================");

      List<ProductUI> result = [];

      for (var product in products) {
        final productName = product['name']?.toString().toLowerCase() ?? '';

        final relatedPrices = prices.where((p) {
          final variantName =
              p['product_variant_name']?.toString().toLowerCase() ?? '';

          return variantName.startsWith(productName);
        }).toList();

        if (relatedPrices.isEmpty) continue;

        relatedPrices.sort((a, b) {
          final aName = a['product_variant_name']?.toString() ?? '';

          final bName = b['product_variant_name']?.toString() ?? '';

          return aName.length.compareTo(bName.length);
        });

        final normal = relatedPrices.firstWhere(
          (p) => p['price_list_code'] == 'NORMAL',
          orElse: () => relatedPrices.first,
        );

        final member = relatedPrices.firstWhere(
          (p) => p['price_list_code'] == 'MEMBER',
          orElse: () => normal,
        );

        final grosir = relatedPrices.firstWhere(
          (p) => p['price_list_code'] == 'GROSIR',
          orElse: () => normal,
        );

        final normalPrice =
            int.tryParse(normal['price'].toString().split('.').first) ?? 0;

        final memberPrice =
            int.tryParse(member['price'].toString().split('.').first) ??
            normalPrice;

        final grosirPrice =
            int.tryParse(grosir['price'].toString().split('.').first) ??
            normalPrice;

        final variantId = normal['product_variant_id']?.toString() ?? '';
        final normalPriceListId = normal['price_list_id']?.toString() ?? '';

        final memberPriceListId = member['price_list_id']?.toString() ?? '';

        final grosirPriceListId = grosir['price_list_id']?.toString() ?? '';
        final grosirMinQty =
            int.tryParse(grosir['min_qty']?.toString() ?? '24') ?? 24;
        // =========================
        // IMAGE
        // =========================

        String imageUrl = "";

        if (product['images'] != null &&
            product['images'] is List &&
            product['images'].isNotEmpty) {
          imageUrl = product['images'][0]['url']?.toString() ?? "";
        }

        result.add(
          ProductUI(
            id: product['id']?.toString() ?? '',
            name: product['name']?.toString() ?? '',
            category: _normalizeCategory(product['category_name']),
            variantName: variantName,

            normalPrice: normalPrice,
            memberPrice: memberPrice,
            grosirPrice: grosirPrice,

            variantId: variantId,

            normalPriceListId: normalPriceListId,
            memberPriceListId: memberPriceListId,
            grosirPriceListId: grosirPriceListId,

            grosirMinQty: grosirMinQty,

            imageUrl: imageUrl,
          ),
        );
      }

      print("✅ TOTAL PRODUK: ${result.length}");
      return result;
    } catch (e) {
      print("🔥 ERROR SERVICE: $e");
      return [];
    }
  }

  static String _normalizeCategory(dynamic raw) {
    final c = raw?.toString().toLowerCase() ?? '';

    if (c.contains("makanan") || c.contains("minuman") || c.contains("snack")) {
      return "makanan & minuman";
    }

    return "lainnya";
  }
}
