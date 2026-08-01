import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';

class ProductCardGrid extends StatelessWidget {
  final ProductUI product;
  final VoidCallback? onTap;

  const ProductCardGrid({
    super.key,
    required this.product,
    this.onTap,
  });

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => "${m[1]}.",
    )}";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 42,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),

            // CONTENT
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 2),

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

                    const SizedBox(height: 2),

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
