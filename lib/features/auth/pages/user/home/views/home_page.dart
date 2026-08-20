import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_section_title.dart';
import 'package:senkuko/core/widgets/app_textfield.dart';
import 'package:senkuko/core/widgets/product_card.dart';
import 'package:senkuko/features/auth/pages/user/home/views/category_product_page.dart';
import 'package:senkuko/features/auth/pages/user/home/views/search_product_page.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_image_service.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_detail_page.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_list_page.dart';
import 'package:senkuko/features/auth/pages/user/promo/services/banner_service.dart';
import 'package:senkuko/features/auth/pages/user/promo/models/banner_model.dart';
import 'package:senkuko/features/auth/pages/user/service.user/auth_guard.dart';
import 'package:senkuko/features/auth/pages/user/voucher/views/voucher_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final box = GetStorage();

  Timer? _accountCheckTimer;

  String get memberName {
    final user = box.read("user");

    if (user == null) return "Member";

    return user["name"] ?? "Member";
  }

  final PageController controller = PageController();

  final TextEditingController searchController = TextEditingController();

  int currentPage = 0;
  List<BannerModel> bannerList = [];
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

    // Observer untuk mendeteksi ketika aplikasi kembali aktif
    WidgetsBinding.instance.addObserver(this);

    // Cek akun saat pertama kali Home dibuka
    checkAccount();

    // Cek status akun setiap 30 detik
    _startAccountCheckTimer();

    fetchBanner();
    fetchProducts();
  }

  // -------------------------------------------------------------------------
  // CEK STATUS AKUN OTOMATIS
  // -------------------------------------------------------------------------

  void _startAccountCheckTimer() {
    _accountCheckTimer?.cancel();

    _accountCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkAccount();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Saat aplikasi kembali dibuka / aktif
    if (state == AppLifecycleState.resumed) {
      checkAccount();
    }
  }

  Future<void> checkAccount() async {
    await AuthGuard.checkUser();
  }

  @override
  void dispose() {
    _accountCheckTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    controller.dispose();
    searchController.dispose();

    super.dispose();
  }

  String formatRupiah(int? price) {
    if (price == null) return "Rp 0";

    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}";
  }

  Future<void> fetchProducts() async {
    try {
      final result = await ProductCombinedService.getHomeProducts();

      final updatedProducts = await Future.wait(
        result.map((product) async {
          try {
            final image = product.imageUrl?.trim().isNotEmpty == true
                ? product.imageUrl
                : await ProductImageService.getProductImage(product.id);

            return product.copyWith(imageUrl: image ?? product.imageUrl);
          } catch (e) {
            return product;
          }
        }),
      );

      if (mounted) {
        setState(() {
          allProducts = updatedProducts.cast<ProductUI>();
          filteredProducts = updatedProducts.cast<ProductUI>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchBanner() async {
    print("LOAD BANNER...");

    final result = await BannerService.getActiveBanner();

    print("BANNER DIDAPAT : ${result.length}");

    if (!mounted) return;

    setState(() {
      bannerList = result;
    });
  }

  void searchProduct(String keyword) {
    if (!mounted) return;

    final results = allProducts.where((p) {
      return p.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  bool _categoryMatches(String productCategory, String selectedCategory) {
    return productCategory.trim().toLowerCase() ==
        selectedCategory.trim().toLowerCase();
  }

  void filterCategory(String selectedCategory) {
    if (!mounted) return;

    if (selectedCategory == "Semua") {
      setState(() {
        filteredProducts = allProducts;
      });
      return;
    }

    final filtered = allProducts.where((p) {
      return _categoryMatches(p.category, selectedCategory);
    }).toList();

    setState(() {
      filteredProducts = filtered;
    });
  }

  List<ProductUI> get newProducts => filteredProducts.toList();

  List<ProductUI> get recommendedProducts => filteredProducts.reversed.toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
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

                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => const SearchProductPage());
                            },

                            child: AbsorbPointer(
                              child: AppTextField(
                                controller: searchController,
                                hint: "Cari produk...",
                                icon: Icons.search,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const SizedBox(height: 16),

                          // BANNER
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final bannerHeight =
                                    (constraints.maxWidth * .36)
                                        .clamp(180.0, 260.0)
                                        .toDouble();

                                return SizedBox(
                              height: bannerHeight,
                              child: bannerList.isEmpty
                                  ? _emptyBanner()
                                  : Stack(
                                      children: [
                                        PageView.builder(
                                          controller: controller,
                                          itemCount: bannerList.length,
                                          onPageChanged: (index) {
                                            setState(() {
                                              currentPage = index;
                                            });
                                          },
                                          itemBuilder: (_, index) {
                                            return banner(index);
                                          },
                                        ),

                                        Positioned(
                                          bottom: 14,
                                          left: 0,
                                          right: 0,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              bannerList.length,
                                              (index) => AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                height: 8,
                                                width: currentPage == index
                                                    ? 22
                                                    : 8,
                                                decoration: BoxDecoration(
                                                  color: currentPage == index
                                                      ? Colors.white
                                                      : Colors.white54,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CATEGORY
                          SizedBox(
                            height: 100,

                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,

                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),

                              itemCount: categories.length,

                              itemBuilder: (context, index) {
                                final icons = [
                                  Icons.apps,
                                  Icons.fastfood,
                                  Icons.child_friendly,
                                  Icons.edit_note,
                                  Icons.chair,
                                  Icons.face,
                                  Icons.shopping_basket,
                                  Icons.storefront,
                                ];

                                return categoryItem(
                                  categories[index],
                                  icons[index],
                                );
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
                            title: "Voucher",

                            onTap: () {
                              Get.to(() => const VoucherPage());
                            },
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 190,

                            child: const VoucherPage(isHome: true),
                          ),
                          const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CATEGORY
  // -------------------------------------------------------------------------

  Widget categoryItem(String category, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (category == "Semua") {
          Get.to(() => const ProductListPage());
        } else {
          Get.to(() => CategoryProductsPage(category: category));
        }
      },

      child: SizedBox(
        width: 80,

        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(icon, color: AppColors.primary, size: 26),
            ),

            const SizedBox(height: 6),

            Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------------------------------------------------------------
  // PRODUCT CARD
  // -------------------------------------------------------------------------

  Widget productList(List<ProductUI> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Tidak ada produk"));
    }

    return SizedBox(
      height: 205,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        itemCount: list.length,

        itemBuilder: (_, index) {
          final product = list[index];

          return ProductCard(
            product: product,

            onTap: () {
              Get.to(() => ProductDetailPage(product: product));
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // BANNER
  // -------------------------------------------------------------------------

  Widget banner(int index) {
    final item = bannerList[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff173b29).withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,

              loadingBuilder: (_, child, loading) {
                if (loading == null) return child;

                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },

              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 60),
                );
              },
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.68),
                    Colors.black.withOpacity(.12),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  //Widget Banner Kosong / Belum Ada
  Widget _emptyBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xff2ecc71), Color(0xff27ae60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white.withOpacity(.08),
            ),
          ),

          Positioned(
            bottom: -30,
            left: -20,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white.withOpacity(.08),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(width: 18),

                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Banner Belum Tersedia",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "Admin belum menambahkan banner promosi.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
