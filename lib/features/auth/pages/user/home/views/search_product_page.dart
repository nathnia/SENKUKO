import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_textfield.dart';
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
          : GridView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: filteredProducts.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,

                crossAxisSpacing: 12,

                mainAxisSpacing: 12,

                childAspectRatio: .68,
              ),

              itemBuilder: (_, i) {
                final product = filteredProducts[i];

                return GestureDetector(
                  onTap: () {
                    Get.to(() => ProductDetailPage(product: product));
                  },

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(16),

                      boxShadow: [
                        BoxShadow(blurRadius: 8, color: Colors.black12),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Container(
                            height: 115,
                            width: double.infinity,
                            color: Colors.grey.shade50,
                            child:
                                product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color: Colors.black54,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.black54,
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  product.name,

                                  maxLines: 2,

                                  overflow: TextOverflow.ellipsis,

                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  product.variantName,

                                  style: const TextStyle(
                                    fontSize: 11,

                                    color: Colors.grey,
                                  ),
                                ),

                                const Spacer(),

                                Text(
                                  rupiah(product.normalPrice),

                                  style: const TextStyle(
                                    color: AppColors.primary,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
