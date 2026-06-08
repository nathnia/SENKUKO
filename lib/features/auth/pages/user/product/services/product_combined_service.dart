import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_ui_model.dart';

class ProductCombinedService {
  static const baseUrl =
      'https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api';

  static Future<List<ProductUI>> getAllProducts() async {
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

      List<ProductUI> result = [];

      for (var product in products) {
        final productName =
            product['name']?.toString().toLowerCase() ?? '';

        //MATCH VARIANT BERDASARKAN NAMA
        final relatedPrices = prices.where((p) {
          final variantName =
              p['product_variant_name']?.toString().toLowerCase() ?? '';
          return variantName.startsWith(productName);
        }).toList();

        if (relatedPrices.isEmpty) continue;

        //SORT BIAR DAPAT VARIANT PALING "UTAMA"
        relatedPrices.sort((a, b) {
          final aName = a['product_variant_name']?.toString() ?? '';
          final bName = b['product_variant_name']?.toString() ?? '';
          return aName.length.compareTo(bName.length);
        });

        //AMBIL HARGA NORMAL
        final normalPrice = relatedPrices.firstWhere(
          (p) => p['price_list_code'] == 'NORMAL',
          orElse: () => relatedPrices.first,
        );

        final price = int.tryParse(
              normalPrice['price']?.toString().split('.').first ?? '0',
            ) ??
            0;

        final variantId =
    normalPrice['product_variant_id']?.toString() ?? "";

final priceListId =
    normalPrice['price_list_id']?.toString() ?? "";

final variantName =
    normalPrice['product_variant_name']?.toString() ?? "-";

        //IMAGE AMAN
        String imageUrl = "";
        if (product['images'] != null &&
            product['images'] is List &&
            product['images'].isNotEmpty) {
          imageUrl =
              product['images'][0]['url']?.toString() ?? "";
        }

        result.add(
  ProductUI(
    id: product['id']?.toString() ?? '',
    name: product['name']?.toString() ?? '',
    category: _normalizeCategory(product['category_name']),
    variantName: variantName,
    price: price,
    imageUrl: imageUrl,
    variantId: variantId,
    priceListId: priceListId, //WAJIB
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

  //FIX FINAL (ANTI ERROR)
  static String _normalizeCategory(dynamic raw) {
    final c = raw?.toString().toLowerCase() ?? '';

    if (c.contains("makanan") || c.contains("minuman")) {
      return "makanan & minuman";
    } else if (c.contains("snack")) {
      return "makanan & minuman";
    }

    return "lainnya";
  }
}