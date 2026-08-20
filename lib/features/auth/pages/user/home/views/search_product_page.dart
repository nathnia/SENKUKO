import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/widgets/app_textfield.dart';
import 'package:senkuko/core/widgets/product_card.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_detail_page.dart';

class SearchProductPage extends StatefulWidget {
  const SearchProductPage({super.key});

  @override
  State<SearchProductPage> createState() => _SearchProductPageState();
}

class _SearchProductPageState extends State<SearchProductPage> {
  final TextEditingController searchController = TextEditingController();

  final FocusNode focusNode = FocusNode();

  List<ProductUI> allProducts = [];
  List<ProductUI> filteredProducts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final data = await ProductCombinedService.getAllProducts();

    if (!mounted) return;

    setState(() {
      allProducts = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  void search(String keyword) {
    final key = keyword.toLowerCase();

    setState(() {
      filteredProducts = allProducts.where((e) {
        return e.name.toLowerCase().contains(key) ||
            e.variantName.toLowerCase().contains(key);
      }).toList();
    });
  }

  String rupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]}.")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        foregroundColor: Colors.black,

        title: AppTextField(
          controller: searchController,
          focusNode: focusNode,
          hint: "Cari produk...",
          icon: Icons.search,
          iconRight: true,
          onChanged: search,
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredProducts.isEmpty
          ? const Center(
              child: Text(
                "Produk tidak ditemukan",

                style: TextStyle(fontSize: 16),
              ),
            )
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
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: .72,
                          ),
                      itemBuilder: (_, index) {
                        final product = filteredProducts[index];

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
