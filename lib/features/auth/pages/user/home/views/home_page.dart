import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/core/widgets/app_section_title.dart';
import 'package:senkuko/core/widgets/app_textfield.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_image_service.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_detail_page.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_list_page.dart';
import 'package:senkuko/features/auth/pages/user/promo/views/promo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = GetStorage();

  String get memberName {
    final user = box.read("user");

    if (user == null) return "Member";

    return user["name"] ?? "Member";
  }

  final PageController controller = PageController();

  final TextEditingController searchController = TextEditingController();

  int currentPage = 0;

  List<ProductUI> allProducts = [];
  List<ProductUI> filteredProducts = [];

  bool isLoading = true;

  final List<String> categories = [
    "Semua",
    "Makanan & Minuman",
    "Produk Bayi",
    "Alat Tulis Kantor",
    "Rumah Tangga",
    "Perawatan Diri",
    "Sembako",
    "UMKM",
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  Future<void> fetchProducts() async {
    try {
      final result = await ProductCombinedService.getAllProducts();
      final updatedProducts = await Future.wait(
        result.map((product) async {
          final image = await ProductImageService.getProductImage(product.id);
          print("PRODUCT: ${product.name}");
          print("IMAGE URL: $image");

          return product.copyWith(imageUrl: image);
        }),
      );
      setState(() {
        allProducts = updatedProducts;
        filteredProducts = updatedProducts;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR UI: $e");
      setState(() => isLoading = false);
    }
  }

  void searchProduct(String keyword) {
    final results = allProducts.where((p) {
      return p.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  String normalizeCategory(String apiCategory) {
    final c = apiCategory.toLowerCase();

    if (c.contains("makanan") || c.contains("minuman") || c.contains("snack")) {
      return "Makanan & Minuman";
    }

    if (c.contains("bayi")) {
      return "Produk Bayi";
    }

    return "Lainnya";
  }

  void filterCategory(String selectedCategory) {
    if (selectedCategory == "Semua") {
      setState(() {
        filteredProducts = allProducts;
      });
      return;
    }

    final filtered = allProducts.where((p) {
      final mapped = normalizeCategory(p.category);
      return mapped == selectedCategory;
    }).toList();

    setState(() {
      filteredProducts = filtered;
    });
  }

  List<ProductUI> get newProducts => filteredProducts.take(5).toList();
  List<ProductUI> get recommendedProducts =>
      filteredProducts.reversed.take(5).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            //HEADER PRO
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, $memberName 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AppTextField(
                            controller: searchController,
                            hint: "Cari produk...",
                            icon: Icons.search,
                            onChanged: searchProduct,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          //BANNER PRO
                          SizedBox(
                            height: 165,
                            child: PageView(
                              controller: controller,
                              onPageChanged: (i) =>
                                  setState(() => currentPage = i),
                              children: [banner(), banner(), banner()],
                            ),
                          ),

                          const SizedBox(height: 10),

                          //DOT
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: currentPage == i ? 12 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: currentPage == i
                                      ? AppColors.primary
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          //CATEGORY
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                return categoryItem(categories[index]);
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          AppSectionTitle(
                            title: "Produk Baru",
                            onTap: () {
                              Get.to(() => const ProductListPage());
                            },
                          ),

                          const SizedBox(height: 10),

                          productList(newProducts),

                          const SizedBox(height: 20),

                          AppSectionTitle(
                            title: "Untuk Anda",
                            onTap: () {
                              Get.to(() => const ProductListPage());
                            },
                          ),

                          const SizedBox(height: 10),

                          productList(recommendedProducts),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  //CATEGORY FIX
  Widget categoryItem(String category) {
    return GestureDetector(
      onTap: () => filterCategory(category),

      child: SizedBox(
        width: 74,

        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Icon(
                Icons.category,
                color: AppColors.primary,
                size: 24,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productList(List<ProductUI> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Tidak ada produk"));
    }

    return SizedBox(
      height: 212,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return productCard(list[index]);
        },
      ),
    );
  }

  Widget productCard(ProductUI product) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailPage(product: product));
      },

      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        product.imageUrl!,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      height: 95,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.image)),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      product.variantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      formatRupiah(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
  }

  //BANNER PRO
  Widget banner() {
    return GestureDetector(
      onTap: () => Get.to(() => const PromoPage()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Promo Spesial",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 8),

              const Text(
                "Diskon Hingga 50%",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Lihat Promo",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
