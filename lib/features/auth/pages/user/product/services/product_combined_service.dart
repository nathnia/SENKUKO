import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_ui_model.dart';

class ProductCombinedService {
  // --------------------------------------------------------------
  // Base URL (ubah bila pindah ke production)
  // --------------------------------------------------------------
  static const String baseUrl =
      'https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev/api';

  // --------------------------------------------------------------
  //  PUBLIC API
  // --------------------------------------------------------------
  /// Home – hanya varian dengan price_list_code = NORMAL
  static Future<List<ProductUI>> getHomeProducts() async {
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
        print('❌ HOME API ERROR');
        return [];
      }

      final List<dynamic> productJson = jsonDecode(productRes.body)['data'] ?? [];
      final List<dynamic> priceJson   = jsonDecode(priceRes.body)['data'] ?? [];

      // Lookup product → id
      final Map<String, Map<String, dynamic>> productLookup = {};
      for (final p in productJson) {
        final map = Map<String, dynamic>.from(p as Map);
        final id = _firstNonEmptyString(
          map['id'],
          map['product_id'],
          map['productId'],
        );
        if (id.isNotEmpty) productLookup[id] = map;
      }

      final List<ProductUI> result = [];

      for (final entry in priceJson) {
        final priceMap = Map<String, dynamic>.from(entry as Map);
        if (priceMap['price_list_code']?.toString().toUpperCase() != 'NORMAL')
          continue;

        final productId = _firstNonEmptyString(
          priceMap['product_id'],
          priceMap['productId'],
          priceMap['id'],
        );
        final productData = productLookup[productId];
        final ui = _buildHomeProductUi(priceMap, productData: productData);
        if (ui != null) result.add(ui);
      }

      return result;
    } catch (e) {
      print('🔥 HOME PRODUCTS ERROR: $e');
      return [];
    }
  }

  /// Semua produk (meng‑gabungkan semua price‑list)
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
        print('❌ API ERROR');
        return [];
      }

      final List<dynamic> productJson = jsonDecode(productRes.body)['data'] ?? [];
      final List<dynamic> priceJson   = jsonDecode(priceRes.body)['data'] ?? [];

      final List<ProductUI> result = [];

      for (final prod in productJson) {
        final ui = _buildProductUi(
          Map<String, dynamic>.from(prod as Map),
          priceJson,
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

  // --------------------------------------------------------------
  //  PRIVATE HELPERS
  // --------------------------------------------------------------

  /// Resolves the **NORMAL** variant (digunakan untuk harga dasar,
  /// stok, gambar, dll.).
  static Map<String, dynamic> resolveBaseVariantEntry(
    List<dynamic> prices,
    Map<String, dynamic> product,
  ) {
    final productName = product['name']?.toString().toLowerCase() ?? '';
    final productId   = product['id']?.toString() ?? '';

    final related = prices.where((p) {
      final variantName = p['product_variant_name']?.toString().toLowerCase() ?? '';
      final pId          = p['product_id']?.toString() ?? '';
      final vId          = p['product_variant_id']?.toString() ?? '';
      final prodVId      = product['product_variant_id']?.toString() ?? '';

      return variantName.startsWith(productName) ||
          pId == productId ||
          vId == prodVId ||
          (pId.isNotEmpty && productId.isNotEmpty && pId.contains(productId)) ||
          (productId.isNotEmpty && pId.isNotEmpty && productId.contains(pId));
    }).toList();

    if (related.isEmpty) return {};

    // Urutkan supaya varian “pendek” (biasanya default) berada di atas.
    related.sort((a, b) {
      final aName = a['product_variant_name']?.toString() ?? '';
      final bName = b['product_variant_name']?.toString() ?? '';
      return aName.length.compareTo(bName.length);
    });

    // Prioritas: is_default → price_list_code = NORMAL → fallback pertama
    try {
      return Map<String, dynamic>.from(
        related.firstWhere(
          (p) => p['is_default'] == true || p['isDefault'] == true,
        ),
      );
    } catch (_) {}

    try {
      return Map<String, dynamic>.from(
        related.firstWhere(
          (p) => p['price_list_code']?.toString().toUpperCase() == 'NORMAL',
        ),
      );
    } catch (_) {}

    return Map<String, dynamic>.from(related.first);
  }

  // --------------------------------------------------------------
  //  Build UI object – Home (hanya variant NORMAL)
  // --------------------------------------------------------------
  static ProductUI? _buildHomeProductUi(
    Map<String, dynamic> priceEntry, {
    Map<String, dynamic>? productData,
  }) {
    if (priceEntry['price_list_code']?.toString().toUpperCase() != 'NORMAL')
      return null;

    final productId = _firstNonEmptyString(
      priceEntry['product_id'],
      priceEntry['productId'],
      priceEntry['id'],
      productData?['id'],
      productData?['product_id'],
      productData?['productId'],
    );

    final productName = _firstNonEmptyString(
      productData?['name'],
      priceEntry['product_name'],
      priceEntry['name'],
      priceEntry['product_variant_name'],
    );

    final variantName = _firstNonEmptyString(
      priceEntry['product_variant_name'],
      productData?['variant_name'],
      productData?['variantName'],
    );

    final int price = _parsePrice(
      priceEntry['price'] ??
          priceEntry['normal_price'] ??
          priceEntry['base_price'] ??
          priceEntry['price_value'] ??
          productData?['price'] ??
          productData?['base_price'] ??
          productData?['price_value'],
    );

    final int stock = _parseInt(
      priceEntry['stock'] ??
          priceEntry['total_stock'] ??
          priceEntry['quantity'] ??
          priceEntry['available_stock'] ??
          productData?['stock'] ??
          productData?['total_stock'] ??
          productData?['quantity'] ??
          productData?['available_stock'],
    );

    final category = _normalizeCategory(
      _firstNonEmptyString(
        productData?['category_name'],
        productData?['category'],
        priceEntry['category_name'],
        priceEntry['category'],
      ),
    );

    final description = _firstNonEmptyString(
      productData?['description'],
      priceEntry['description'],
    );

    // Gambar (cek semua kemungkinan, tambahkan https: bila hanya //)
    final String imageUrl = _extractImageUrl(productData ?? priceEntry);

    return ProductUI(
      id: productId,
      name: productName,
      category: category,
      variantName: variantName,
      description: description,
      normalPrice: price,
      memberPrice: price,
      grosirPrice: price,
      variantId: _firstNonEmptyString(
        priceEntry['product_variant_id'],
        priceEntry['variant_id'],
        productData?['product_variant_id'],
      ),
      normalPriceListId: _firstNonEmptyString(
        priceEntry['price_list_id'],
        priceEntry['priceListId'],
      ),
      memberPriceListId: '',
      grosirPriceListId: '',
      grosirMinQty: 24,
      stock: stock,
      imageUrl: imageUrl,
    );
  }

  // --------------------------------------------------------------
  //  Build UI object – All products (semua price‑list)
  // --------------------------------------------------------------
  static ProductUI? _buildProductUi(
    Map<String, dynamic> product,
    List<dynamic> allPrices,
  ) {
    final productName = product['name']?.toString().toLowerCase() ?? '';
    final productId   = product['id']?.toString() ?? '';

    // Ambil semua price entry yang berhubungan dengan produk ini
    final related = allPrices.where((p) {
      final vName = p['product_variant_name']?.toString().toLowerCase() ?? '';
      final pId   = p['product_id']?.toString() ?? '';
      final vId   = p['product_variant_id']?.toString() ?? '';
      final prodVId = product['product_variant_id']?.toString() ?? '';

      return vName.startsWith(productName) ||
          pId == productId ||
          vId == prodVId ||
          (pId.isNotEmpty && productId.isNotEmpty && pId.contains(productId)) ||
          (productId.isNotEmpty && pId.isNotEmpty && productId.contains(pId));
    }).toList();

    // ----------------------------------------------
    // Base (NORMAL) variant – dipakai untuk stok & gambar
    // ----------------------------------------------
    final baseVariant = related.isEmpty
        ? <String, dynamic>{}
        : resolveBaseVariantEntry(related, product);

    // fallback bila tidak ada varian NORMAL
    final fallback = related.isNotEmpty
        ? Map<String, dynamic>.from(related.first as Map)
        : <String, dynamic>{};

    final normal = baseVariant.isEmpty ? fallback : baseVariant;

    // ----------------------------------------------
    // Harga khusus: MEMBER & GROSIR
    // ----------------------------------------------
    final member = related.firstWhere(
          (p) => p['price_list_code']?.toString().toUpperCase() == 'MEMBER',
        orElse: () => normal.isEmpty ? fallback : normal,
    );

    final grosir = related.firstWhere(
          (p) => p['price_list_code']?.toString().toUpperCase() == 'GROSIR',
        orElse: () => normal.isEmpty ? fallback : normal,
    );

    // ----------------------------------------------
    // Helper konversi harga
    // ----------------------------------------------
    int _priceFrom(dynamic src) => _parsePrice(src);
    final int normalPrice = _priceFrom(normal['price']) != 0
        ? _priceFrom(normal['price'])
        : _priceFrom(product['price']) != 0
            ? _priceFrom(product['price'])
            : 0;

    final int memberPrice = _priceFrom(member['price']) != 0
        ? _priceFrom(member['price'])
        : normalPrice;

    final int grosirPrice = _priceFrom(grosir['price']) != 0
        ? _priceFrom(grosir['price'])
        : normalPrice;

    // ----------------------------------------------
    // Stok – coba ambil dari NORMAL, bila tidak ada coba dari
    // field lain yang mungkin ada.
    // ----------------------------------------------
    final int stock = _parseInt(
      normal['stock'] ??
          normal['total_stock'] ??
          normal['quantity'] ??
          normal['available_stock'] ??
          product['stock'] ??
          product['total_stock'] ??
          product['quantity'] ??
          product['available_stock'] ??
          0,
    );

    // ----------------------------------------------
    // Gambar
    // ----------------------------------------------
    final String imageUrl = _extractImageUrl(product);

    // ----------------------------------------------
    // Return UI object
    // ----------------------------------------------
    return ProductUI(
      id: product['id']?.toString() ?? '',
      name: product['name']?.toString() ?? '',
      category: _normalizeCategory(product['category_name']),
      variantName: normal['product_variant_name']?.toString() ?? '',
      description: product['description']?.toString() ?? '',
      normalPrice: normalPrice,
      memberPrice: memberPrice,
      grosirPrice: grosirPrice,
      variantId: normal['product_variant_id']?.toString() ?? '',
      normalPriceListId: normal['price_list_id']?.toString() ?? '',
      memberPriceListId: member['price_list_id']?.toString() ?? '',
      grosirPriceListId: grosir['price_list_id']?.toString() ?? '',
      grosirMinQty:
          int.tryParse(grosir['min_qty']?.toString() ?? '24') ?? 24,
      stock: stock,
      imageUrl: imageUrl,
    );
  }

  // --------------------------------------------------------------
  //  Normalisasi kategori (menyederhanakan string)
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
  static String _firstNonEmptyStringFromList(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String _firstNonEmptyString(
    Object? v1, [
    Object? v2,
    Object? v3,
    Object? v4,
    Object? v5,
    Object? v6,
  ]) {
    return _firstNonEmptyStringFromList([v1, v2, v3, v4, v5, v6]);
  }

  /// Parse integer – mengabaikan titik/koma serta spasi.
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

  /// **Perbaikan utama** – menangani harga yang mungkin berupa
  ///  * 12.500 (titik = ribuan) → 12500
  ///  * 125.00 (titik = desimal) → 125
  static int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    final raw = value.toString().trim();
    if (raw.isEmpty) return 0;

    var cleaned = raw.replaceAll(',', '');

    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      // Jika ada dua digit di belakang titik → dianggap desimal
      if (parts.length == 2 && parts[1].length == 2) {
        cleaned = parts[0]; // buang desimal sepenuhnya
      } else {
        // Titik = ribuan
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return int.tryParse(cleaned) ?? 0;
  }

  /// **Ekstrak gambar** dari semua struktur yang mungkin.
  /// - List `images` → ambil `url` dari elemen pertama.
  /// - Field tunggal: `image_url`, `imageUrl`, `image`, `thumbnail`, `photo`.
  /// - Jika URL dimulai dengan `//` → tambahkan `https:`.
  static String _extractImageUrl(Map<String, dynamic> data) {
    // 1️⃣ List of images
    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        final url = first['url'] ?? first['image'] ?? first['src'];
        if (url != null) return _fixScheme(url.toString());
      }
    }

    // 2️⃣ Direct fields
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

    // 3️⃣ Tidak ada gambar → kosong
    return '';
  }

  /// Tambahkan scheme `https:` bila URL dimulai dengan `//`.
  static String _fixScheme(String url) {
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}