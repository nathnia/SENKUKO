import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_ui_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductCombinedService {
  static final String baseUrl =
      dotenv.env['BASE_URL']!;

  /// Home – 1 card per PARENT produk (sama seperti getAllProducts).
  static Future<List<ProductUI>> getHomeProducts() async {
    return getAllProducts();
  }

  /// Semua produk – 1 card per PARENT produk, memakai varian "dasar"
  /// (is_base_unit = 1, biasanya satuan pcs) untuk harga/stok yang
  /// ditampilkan di listing. Varian lain dipilih lewat dropdown di detail.
  static Future<List<ProductUI>> getAllProducts() async {
    try {
      final raw = await _fetchRaw();
      if (raw == null) return [];

      final products = raw['products']!;
      final variants = raw['variants']!;
      final prices = raw['prices']!;

      final pricesByVariant = _groupPricesByVariant(prices);

      final List<ProductUI> result = [];

      for (final p in products) {
        final product = Map<String, dynamic>.from(p as Map);
        final productId = product['id']?.toString() ?? '';
        if (productId.isEmpty) continue;

        final productVariants = variants
            .map((v) => Map<String, dynamic>.from(v as Map))
            .where((v) => v['product_id']?.toString() == productId)
            .toList();

        if (productVariants.isEmpty) continue; // tidak ada varian = tidak bisa dijual

        // Varian dasar: prioritas is_base_unit == 1, kalau tidak ada pakai yang pertama.
        final baseVariant = productVariants.firstWhere(
          (v) => v['is_base_unit'] == 1 || v['is_base_unit'] == true,
          orElse: () => productVariants.first,
        );

        final ui = _buildProductUiFromVariant(
          product: product,
          variant: baseVariant,
          pricesByVariant: pricesByVariant,
        );
        if (ui != null) result.add(ui);
      }

      print('✅ TOTAL PRODUK: ${result.length}');
      return result;
    } catch (e) {
      print('🔥 ERROR SERVICE: $e');
      return [];
    }
  }

  /// Semua VARIAN milik satu produk (id + nama produk), masing-masing
  /// dengan stok & harga MILIK VARIAN ITU SENDIRI (stock_qty per varian,
  /// bukan ikut parent). Dipakai untuk dropdown di halaman detail.
  static Future<List<ProductUI>> getProductVariants(
    String productId,
    String productName,
  ) async {
    try {
      final raw = await _fetchRaw();
      if (raw == null) return [];

      final products = raw['products']!;
      final variants = raw['variants']!;
      final prices = raw['prices']!;

      final pricesByVariant = _groupPricesByVariant(prices);

      Map<String, dynamic>? product;
      for (final p in products) {
        final map = Map<String, dynamic>.from(p as Map);
        if (map['id']?.toString() == productId) {
          product = map;
          break;
        }
      }
      if (product == null) return [];

      final productVariants = variants
          .map((v) => Map<String, dynamic>.from(v as Map))
          .where((v) => v['product_id']?.toString() == productId)
          .toList();

      final List<ProductUI> result = [];
      for (final variant in productVariants) {
        final ui = _buildProductUiFromVariant(
          product: product,
          variant: variant,
          pricesByVariant: pricesByVariant,
        );
        if (ui != null) result.add(ui);
      }

      return result;
    } catch (e) {
      print('🔥 VARIANTS ERROR: $e');
      return [];
    }
  }

  // --------------------------------------------------------------
  //  FETCH MENTAH (products + variants + prices)
  // --------------------------------------------------------------
  static Future<Map<String, List<dynamic>>?> _fetchRaw() async {
    final productRes = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: {"Accept": "application/json"},
    );
    final variantRes = await http.get(
      Uri.parse('$baseUrl/api/product-variants'), // ⚠️ cek/ganti kalau URL aslinya beda
      headers: {"Accept": "application/json"},
    );
    final priceRes = await http.get(
      Uri.parse('$baseUrl/api/product-prices'),
      headers: {"Accept": "application/json"},
    );

    if (productRes.statusCode != 200 ||
        variantRes.statusCode != 200 ||
        priceRes.statusCode != 200) {
      print(
        '❌ API ERROR — products:${productRes.statusCode} '
        'variants:${variantRes.statusCode} prices:${priceRes.statusCode}',
      );
      return null;
    }

    final List<dynamic> productJson = jsonDecode(productRes.body)['data'] ?? [];
    final List<dynamic> variantJson = jsonDecode(variantRes.body)['data'] ?? [];
    final List<dynamic> priceJson   = jsonDecode(priceRes.body)['data'] ?? [];

    return {
      'products': productJson,
      'variants': variantJson,
      'prices': priceJson,
    };
  }

  /// Kelompokkan entry harga berdasarkan product_variant_id, supaya bisa
  /// diambil cepat per varian.
  static Map<String, List<Map<String, dynamic>>> _groupPricesByVariant(
    List<dynamic> priceJson,
  ) {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final e in priceJson) {
      final entry = Map<String, dynamic>.from(e as Map);
      final variantId = entry['product_variant_id']?.toString() ?? '';
      if (variantId.isEmpty) continue;
      map.putIfAbsent(variantId, () => []).add(entry);
    }
    return map;
  }

  // --------------------------------------------------------------
  //  Build UI object dari 1 (product, variant) pair
  // --------------------------------------------------------------
  static ProductUI? _buildProductUiFromVariant({
    required Map<String, dynamic> product,
    required Map<String, dynamic> variant,
    required Map<String, List<Map<String, dynamic>>> pricesByVariant,
  }) {
    final variantId = variant['id']?.toString() ?? '';
    final variantPrices = pricesByVariant[variantId] ?? [];

    if (variantPrices.isEmpty) return null; // tidak ada harga sama sekali

    Map<String, dynamic> pickPrice(String code, Map<String, dynamic> fallback) {
      return variantPrices.firstWhere(
        (p) => p['price_list_code']?.toString().toUpperCase() == code,
        orElse: () => fallback,
      );
    }

    final normalEntry = pickPrice('NORMAL', variantPrices.first);
    final memberEntry = pickPrice('MEMBER', normalEntry);
    final grosirEntry = pickPrice('GROSIR', normalEntry);

    final int normalPrice = _parsePrice(normalEntry['price']);
    final int memberPrice =
        _parsePrice(memberEntry['price']) != 0 ? _parsePrice(memberEntry['price']) : normalPrice;
    final int grosirPrice =
        _parsePrice(grosirEntry['price']) != 0 ? _parsePrice(grosirEntry['price']) : normalPrice;

    // STOK: langsung dari stock_qty milik VARIAN ini, bukan dari parent.
    final int stock = _parseInt(variant['stock_qty']);

    return ProductUI(
      id: product['id']?.toString() ?? '',
      name: product['name']?.toString() ?? '',
      category: _normalizeCategory(product['category_name']),
      variantName: variant['name']?.toString() ?? '',
      description: product['description']?.toString() ?? '',
      normalPrice: normalPrice,
      memberPrice: memberPrice,
      grosirPrice: grosirPrice,
      variantId: variantId,
      normalPriceListId: normalEntry['price_list_id']?.toString() ?? '',
      memberPriceListId: memberEntry['price_list_id']?.toString() ?? '',
      grosirPriceListId: grosirEntry['price_list_id']?.toString() ?? '',
      grosirMinQty: int.tryParse(grosirEntry['min_qty']?.toString() ?? '24') ?? 24,
      stock: stock,
      imageUrl: _extractImageUrl(product),
    );
  }

  // --------------------------------------------------------------
  //  Normalisasi kategori
  // --------------------------------------------------------------
  static String _normalizeCategory(dynamic raw) {
    final cat = raw?.toString().toLowerCase() ?? '';

    if (cat.contains('makanan') ||
        cat.contains('minuman') ||
        cat.contains('snack')) {
      return 'makanan & minuman';
    }
    if (cat.contains('bayi')) return 'produk bayi';
    if (cat.contains('alat') ||
        cat.contains('tulis') ||
        cat.contains('kantor')) {
      return 'alat tulis kantor';
    }
    if (cat.contains('rumah')) return 'rumah tangga';
    if (cat.contains('perawatan') || cat.contains('kecantikan')) {
      return 'perawatan diri';
    }
    if (cat.contains('sembako')) return 'sembako';
    if (cat.contains('umkm')) return 'umkm';

    return 'lainnya';
  }

  // --------------------------------------------------------------
  //  Helper umum
  // --------------------------------------------------------------
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    final txt = value
        .toString()
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    return int.tryParse(txt) ?? 0;
  }

  /// Menangani harga string seperti "3500.00" (desimal, bukan ribuan).
  static int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    final raw = value.toString().trim();
    if (raw.isEmpty) return 0;

    var cleaned = raw.replaceAll(',', '');

    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length == 2) {
        cleaned = parts[0]; // desimal, buang
      } else {
        cleaned = cleaned.replaceAll('.', ''); // titik = ribuan
      }
    }

    return int.tryParse(cleaned) ?? 0;
  }

  static String _extractImageUrl(Map<String, dynamic> data) {
    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      final primary = images.firstWhere(
        (img) => img is Map && img['is_primary'] == true,
        orElse: () => images.first,
      );
      if (primary is Map) {
        final url = primary['url'] ?? primary['image'] ?? primary['src'];
        if (url != null) return _fixScheme(url.toString());
      }
    }

    final candidates = [
      data['image_url'],
      data['imageUrl'],
      data['image'],
      data['thumbnail'],
      data['photo'],
    ];
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return _fixScheme(c.toString());
      }
    }

    return '';
  }

  static String _fixScheme(String url) {
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}