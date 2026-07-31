import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';

class ProductCard extends StatelessWidget {
  final ProductUI product;
  final VoidCallback? onTap;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width = 145,
  });

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => "${m[1]}.",
    )}";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: width,

        margin: const EdgeInsets.only(right: 12),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // IMAGE
            Container(
              height: 110,

              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.grey.shade50,

                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),

              child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),

                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,

                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },

                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 45,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 45,
                        color: Colors.grey,
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
                        color: Colors.grey.shade600,
                        fontSize: 11,
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

                    const SizedBox(height: 4),

                    Text(
                      product.stock > 0
                          ? "Stok : ${product.stock}"
                          : "Stok Habis",

                      style: TextStyle(
                        fontSize: 10,

                        fontWeight: FontWeight.w600,

                        color: product.stock > 0
                            ? Colors.green
                            : Colors.red,
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
}