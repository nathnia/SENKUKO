import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/product_card.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final String? keyword;

  const ProductListPage({super.key, this.keyword});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<ProductUI> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Mengambil semua produk (bukan hanya home) karena di halaman daftar
  /// biasanya pengguna ingin melihat *semua* barang.
  Future<void> _loadProducts() async {
    try {
      final data = await ProductCombinedService.getAllProducts();
      if (!mounted) return;

      List<ProductUI> result = data;

      if (widget.keyword != null && widget.keyword!.trim().isNotEmpty) {
        result = data.where((e) {
          return e.name.toLowerCase().contains(widget.keyword!.toLowerCase());
        }).toList();
      }

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // -----------------------------------------------------------------
  // Helper format Rupiah (sama seperti pada halaman Home)
  // FIX: sebelumnya regex pakai '\\d' (double backslash) di dalam raw
  // string, sehingga pola yang dicari adalah literal "\d" bukan digit,
  // akibatnya harga tidak pernah diberi titik ribuan dengan benar.
  // -----------------------------------------------------------------
  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produk"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 5
                    : constraints.maxWidth >= 700
                    ? 4
                    : 2;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .72,
                          ),
                      itemBuilder: (_, index) {
                        final product = products[index];

                        return ProductCard(
                          product: product,
                          isInGrid: true,
                          onTap: () {
                            Get.to(() => ProductDetailPage(product: product));
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
