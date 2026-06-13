import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/product/views/product_detail_page.dart';
import 'package:get/get.dart';

class CategoryProductsPage extends StatefulWidget {
final String category;

const CategoryProductsPage({
super.key,
required this.category,
});

@override
State<CategoryProductsPage> createState() =>
_CategoryProductsPageState();
}

class _CategoryProductsPageState
extends State<CategoryProductsPage> {
List<ProductUI> products = [];

bool loading = true;

@override
void initState() {
super.initState();
loadProducts();
}

String normalizeCategory(String apiCategory) {
final c = apiCategory.toLowerCase();

if (c.contains("makanan") ||
    c.contains("minuman") ||
    c.contains("snack")) {
  return "Makanan & Minuman";
}

if (c.contains("bayi")) {
  return "Produk Bayi";
}

if (c.contains("alat")) {
  return "Alat Tulis Kantor";
}

if (c.contains("rumah")) {
  return "Rumah Tangga";
}

if (c.contains("perawatan")) {
  return "Perawatan Diri";
}

if (c.contains("sembako")) {
  return "Sembako";
}

if (c.contains("umkm")) {
  return "UMKM";
}

return "Lainnya";

}

Future<void> loadProducts() async {
final all =
await ProductCombinedService.getAllProducts();

setState(() {
  products = all.where((e) {
    return normalizeCategory(e.category)
            .toLowerCase() ==
        widget.category.toLowerCase();
  }).toList();

  loading = false;
});

}

String rupiah(int value) {
return "Rp ${value.toString().replaceAllMapped(
RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
(m) => '${m[1]}.',
)}";
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(widget.category),
backgroundColor: AppColors.primary,
),

  body: loading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : products.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 90,
                  color: Colors.grey.shade400,
                ),

                const SizedBox(height: 16),

                Text(
                  "Belum ada produk",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Kategori ${widget.category}\nmasih kosong",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
          padding: const EdgeInsets.all(12),

          itemCount: products.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: .72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),

          itemBuilder: (_, i) {
            final p = products[i];

            return GestureDetector(
              onTap: () {
                Get.to(
                  () => ProductDetailPage(
                    product: p,
                  ),
                );
              },

              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        p.imageUrl ?? "",
                        fit: BoxFit.contain,
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                          ),

                          const SizedBox(
                              height: 5),

                          Text(
                            rupiah(
                                p.normalPrice),
                            style:
                                const TextStyle(
                              color: AppColors
                                  .primary,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
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
