import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_image_service.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<ProductUI> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
  try {
    final result = await ProductCombinedService.getAllProducts();

    final updatedProducts = await Future.wait(
      result.map((product) async {
        final image =
            await ProductImageService.getProductImage(product.id);

        return product.copyWith(imageUrl: image);
      }),
    );

    setState(() {
      products = updatedProducts;
      isLoading = false;
    });

  } catch (e) {
    print(e);
    setState(() => isLoading = false);
  }
}

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => "${m[1]}.",
    )}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produk"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
  final ProductUI product = products[index];

  return GestureDetector(
    onTap: () {
      Get.to(() => ProductDetailPage(product: product));
    },

    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),

            child: SizedBox(
              height: 115,
              width: double.infinity,

              child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty

                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                    )

                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image),
                      ),
                    ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    formatRupiah(product.price),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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