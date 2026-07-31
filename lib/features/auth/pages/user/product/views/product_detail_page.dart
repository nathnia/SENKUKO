import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/features/auth/pages/user/checkout/binding/checkout_binding.dart';
import 'package:senkuko/features/auth/pages/user/product/models/product_ui_model.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/views/checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductUI product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<ProductUI> variants = [];

  late ProductUI selected;

  bool isLoadingVariants = true;

  @override
  void initState() {
    super.initState();
    selected = widget.product;
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    try {
      final result = await ProductCombinedService.getProductVariants(
        widget.product.id,
        widget.product.name,
      );

      if (!mounted) return;

      setState(() {
        variants = result.isEmpty ? [widget.product] : result;

        final match = variants.firstWhere(
          (v) => v.variantId == selected.variantId,
          orElse: () => variants.first,
        );

        selected = match;
        isLoadingVariants = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingVariants = false);
      }
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
    final product = selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Detail Produk"),
        backgroundColor: AppColors.card,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // IMAGE
          Container(
            height: 250,
            color: AppColors.border,
            child: product.imageUrl != null &&
                    product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(Icons.image, size: 100),
                  ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // INFO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Text(
                              formatRupiah(product.price),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              product.category,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              "Stok : ${product.stock}",
                              style: TextStyle(
                                color: product.stock > 0
                                    ? AppColors.primary
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // PILIH VARIAN
                        if (isLoadingVariants)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (variants.length > 1) ...[
                          const Text(
                            "Pilih Varian",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selected.variantId,
                                items: variants.map((v) {
                                  final label = v.variantName.isNotEmpty
                                      ? v.variantName
                                      : v.name;

                                  return DropdownMenuItem(
                                    value: v.variantId,
                                    child: Text(
                                      "$label  •  ${formatRupiah(v.normalPrice)}",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (variantId) {
                                  if (variantId == null) return;

                                  final match = variants.firstWhere(
                                    (v) => v.variantId == variantId,
                                    orElse: () => selected,
                                  );

                                  setState(() {
                                    selected = match;
                                  });
                                },
                              ),
                            ),
                          ),
                        ] else
                          Text(
                            product.variantName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DESKRIPSI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deskripsi Produk",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          product.description.isEmpty
                              ? "Tidak ada deskripsi."
                              : product.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.card,
            child: Row(
              children: [
                // MASUKKAN KERANJANG
                Expanded(
                  child: AppButton(
                    text: "Masukkan Keranjang",
                    outlined: true,
                    onPressed: product.stock == 0
                        ? null
                        : () {
                            showAddToCartSheet(
                              context,
                              product,
                            );
                          },
                  ),
                ),

                const SizedBox(width: 10),

                // BELI SEKARANG
                Expanded(
                  child: AppButton(
                    text: "Beli Sekarang",
                    onPressed: product.stock == 0
                        ? null
                        : () {
                            showBuyNowSheet(
                              context,
                              product,
                            );
                          },
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

// ============================================================================
// BUY NOW
// ============================================================================

void showBuyNowSheet(
  BuildContext context,
  ProductUI product,
) {
  int qty = 1;

  final TextEditingController qtyController =
      TextEditingController(text: "1");

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => "${m[1]}.",
        )}";
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withAlpha(77),
              child: GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.border,
                                      child: const Icon(Icons.image),
                                    ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(product.name),

                                  const SizedBox(height: 4),

                                  Text(
                                    formatRupiah(
                                      product.price,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jumlah"),

                            Row(
                              children: [
                                // MINUS
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (qty > 1) {
                                      setState(() {
                                        qty--;

                                        qtyController.text =
                                            qty.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );
                                      });
                                    }
                                  },
                                ),

                                SizedBox(
                                  width: 55,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType:
                                        TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                    ],
                                    textAlign: TextAlign.center,
                                    selectAllOnFocus: true,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        setState(() {
                                          qty = 0;
                                        });
                                        return;
                                      }

                                      final inputQty =
                                          int.tryParse(value) ?? 0;

                                      if (inputQty >
                                          product.stock) {
                                        qtyController.text =
                                            product.stock.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );

                                        setState(() {
                                          qty = product.stock;
                                        });
                                        return;
                                      }

                                      setState(() {
                                        qty = inputQty;
                                      });
                                    },
                                    onEditingComplete: () {
                                      if (qty < 1) {
                                        qtyController.text = "1";

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          const TextPosition(
                                            offset: 1,
                                          ),
                                        );

                                        setState(() {
                                          qty = 1;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                // PLUS
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    if (qty < product.stock) {
                                      setState(() {
                                        qty++;

                                        qtyController.text =
                                            qty.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );
                                      });
                                    } else {
                                      Get.snackbar(
                                        "Stok Tidak Cukup",
                                        "Jumlah maksimal adalah ${product.stock}",
                                        snackPosition:
                                            SnackPosition.BOTTOM,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total"),

                            Text(
                              formatRupiah(
                                product.price * qty,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: qty < 1
                                ? null
                                : () {
                                    Navigator.pop(context);

                                    Get.to(
                                      () => CheckoutPage(
                                        directItems: [
                                          CartItem(
                                            id: product.id,
                                            name: product.name,
                                            price: product.price,
                                            qty: qty,
                                            variantId:
                                                product.variantId,
                                            priceListId:
                                                product
                                                    .normalPriceListId,
                                            imageUrl:
                                                product.imageUrl,
                                            stock: product.stock,
                                          ),
                                        ],
                                        isFromCart: false,
                                      ),
                                      binding: CheckoutBinding(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Checkout"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// ADD TO CART
// ============================================================================

void showAddToCartSheet(
  BuildContext context,
  ProductUI product,
) {
  final cart = Get.find<CartController>();

  int qty = 1;

  final TextEditingController qtyController =
      TextEditingController(text: "1");

  String formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => "${m[1]}.",
        )}";
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withAlpha(77),
              child: GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.border,
                                      child: const Icon(Icons.image),
                                    ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    formatRupiah(
                                      product.price,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Jumlah",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Row(
                              children: [
                                // MINUS
                                IconButton(
                                  onPressed: () {
                                    if (qty > 1) {
                                      setState(() {
                                        qty--;

                                        qtyController.text =
                                            qty.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),

                                SizedBox(
                                  width: 55,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType:
                                        TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                    ],
                                    textAlign: TextAlign.center,
                                    selectAllOnFocus: true,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        setState(() {
                                          qty = 0;
                                        });
                                        return;
                                      }

                                      final inputQty =
                                          int.tryParse(value) ?? 0;

                                      if (inputQty >
                                          product.stock) {
                                        qtyController.text =
                                            product.stock.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );

                                        setState(() {
                                          qty = product.stock;
                                        });
                                        return;
                                      }

                                      setState(() {
                                        qty = inputQty;
                                      });
                                    },
                                    onEditingComplete: () {
                                      if (qty < 1) {
                                        qtyController.text = "1";

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          const TextPosition(
                                            offset: 1,
                                          ),
                                        );

                                        setState(() {
                                          qty = 1;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                // PLUS
                                IconButton(
                                  onPressed: () {
                                    if (qty < product.stock) {
                                      setState(() {
                                        qty++;

                                        qtyController.text =
                                            qty.toString();

                                        qtyController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: qtyController
                                                .text
                                                .length,
                                          ),
                                        );
                                      });
                                    } else {
                                      Get.snackbar(
                                        "Stok Tidak Cukup",
                                        "Jumlah maksimal adalah ${product.stock}",
                                        snackPosition:
                                            SnackPosition.BOTTOM,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total"),

                            Text(
                              formatRupiah(
                                product.price * qty,
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: qty < 1
                                ? null
                                : () {
                                    cart.addItem(
                                      product.id,
                                      product.name,
                                      product.price,
                                      product.variantId,
                                      product.priceListId,
                                      product.imageUrl,
                                      product.stock,
                                      qty: qty,
                                    );

                                    Navigator.pop(context);

                                    Get.snackbar(
                                      "Berhasil",
                                      "$qty produk berhasil ditambahkan",
                                      snackPosition:
                                          SnackPosition.BOTTOM,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Masukkan ke Keranjang",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}