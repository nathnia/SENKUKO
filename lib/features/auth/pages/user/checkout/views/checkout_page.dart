import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';
import 'package:senkuko/features/auth/pages/user/promo/models/promotion_model.dart';
import 'package:senkuko/features/auth/pages/user/service.user/auth_guard.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? directItems;
  final bool isFromCart;

  const CheckoutPage({super.key, this.directItems, this.isFromCart = false});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartController _cart = Get.find<CartController>();
  final CheckoutController _checkout = Get.find<CheckoutController>();
  final GetStorage _store = GetStorage();

  late List<CartItem> _items;
  late int _subtotal;

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    _prepareItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previewDiscounts();
    });
  }

  @override
  void didUpdateWidget(covariant CheckoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.directItems != widget.directItems ||
        oldWidget.isFromCart != widget.isFromCart) {
      _prepareItems();
      _previewDiscounts();
    }
  }

  void _prepareItems() {
    _items = widget.directItems ?? _cart.selectedItems;

    _subtotal = _items.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.qty),
    );
  }

  Future<void> _previewDiscounts() async {
    await _checkout.previewDiscounts(
      subtotal: _subtotal,
      items: _items,
      priceListId: _checkout.selectedPriceListId?.value.isNotEmpty == true
          ? _checkout.selectedPriceListId!.value
          : null,
    );
  }

  String _formatRupiah(int price) {
    return _currencyFormatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user =
        _store.read<Map<String, dynamic>>('user') ?? {};

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Obx(() {
        /*
        ============================================================
        KUNCI PERBAIKAN
        ============================================================

        Semua widget yang menggunakan:

        - totalPrice
        - promoDiscountAmount
        - voucherDiscountAmount
        - isLoading

        dibungkus Obx.

        Jadi ketika backend mengembalikan total setelah diskon,
        seluruh UI checkout akan rebuild.
        */

        final int promoDiscount = _checkout.promoDiscountAmount.value;

        final int voucherDiscount = _checkout.voucherDiscountAmount.value;

        final int currentTotal = (_subtotal - promoDiscount - voucherDiscount)
            .clamp(0, _subtotal);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AppCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // =====================================================
                          // ALAMAT
                          // =====================================================
                          _ShippingAddressCard(
                            userName: user['name'] ?? '-',
                            userPhone: user['phone'] ?? '-',
                            checkout: _checkout,
                          ),

                          const _CheckoutSectionDivider(),

                          // =====================================================
                          // PRODUK
                          // =====================================================
                          _ProductListCard(items: _items),

                          const _CheckoutSectionDivider(),

                          // =====================================================
                          // PAYMENT
                          // =====================================================
                          _PaymentMethodCard(checkout: _checkout),

                          const _CheckoutSectionDivider(),

                          // =====================================================
                          // PROMO & VOUCHER
                          // =====================================================
                          _PromoVoucherCard(
                            checkout: _checkout,
                            subtotal: _subtotal,
                            items: _items,
                          ),

                          const _CheckoutSectionDivider(),

                          // =====================================================
                          // SUMMARY
                          // =====================================================
                          _SummaryCard(
                            checkout: _checkout,
                            subtotal: _subtotal,
                            total: currentTotal,
                            format: _formatRupiah,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // =============================================================
            // BOTTOM BAR
            // =============================================================
            _BottomBar(
              total: currentTotal,
              format: _formatRupiah,
              isLoading: _checkout.isLoading,
              onPayPressed: () {
                if (_checkout.addressController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Alamat kosong',
                    'Silakan isi alamat pengiriman.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (_items.isEmpty) {
                  Get.snackbar(
                    'Keranjang kosong',
                    'Tidak ada produk untuk checkout.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                _checkout.checkout(
                  fromCart: widget.isFromCart,
                  items: _items,
                  priceListId:
                      _checkout.selectedPriceListId?.value.isNotEmpty == true
                      ? _checkout.selectedPriceListId!.value
                      : null,
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _CheckoutSectionDivider extends StatelessWidget {
  const _CheckoutSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, thickness: 1, color: Color(0xffe9edf1)),
    );
  }
}

// ============================================================================
// SHIPPING ADDRESS
// ============================================================================

class _ShippingAddressCard extends StatelessWidget {
  final String userName;
  final String userPhone;
  final CheckoutController checkout;

  const _ShippingAddressCard({
    required this.userName,
    required this.userPhone,
    required this.checkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.location_on,
          title: 'Alamat Pengiriman',
        ),

        const SizedBox(height: 16),

        Text(
          userName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 4),

        Text(userPhone, style: const TextStyle(color: Colors.grey)),

        const Divider(height: 24),

        Obx(() {
          if (!checkout.isEditingAddress.value) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkout.addressController.text.isEmpty
                      ? 'Alamat belum diisi'
                      : checkout.addressController.text,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      checkout.isEditingAddress.value = true;
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              TextField(
                controller: checkout.addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alamat Pengiriman',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final allowed = await AuthGuard.checkUser();

                        if (!allowed) return;

                        // proses checkout
                        checkout.isEditingAddress.value = false;
                        await checkout.loadProfile();
                      },
                      child: const Text('Batal'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        checkout.isEditingAddress.value = false;
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),

        const SizedBox(height: 16),

        TextField(
          controller: checkout.noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Catatan untuk kurir (opsional)',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRODUCT LIST
// ============================================================================

class _ProductListCard extends StatelessWidget {
  final List<CartItem> items;

  const _ProductListCard({required this.items});

  String _formatRupiah(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        const SizedBox(height: 16),

        if (items.isEmpty)
          const Center(child: Text('Tidak ada item yang dipilih.'))
        else
          ...items.map(_itemTile),
      ],
    );
  }

  Widget _itemTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),

            child: item.imageUrl?.isNotEmpty == true
                ? Image.network(
                    item.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _imagePlaceholder();
                    },
                  )
                : _imagePlaceholder(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                Text(
                  _formatRupiah(item.price),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'x${item.qty}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image),
    );
  }
}

// ============================================================================
// PAYMENT METHOD
// ============================================================================

class _PaymentMethodCard extends StatelessWidget {
  final CheckoutController checkout;

  const _PaymentMethodCard({required this.checkout});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        const SizedBox(height: 12),

        Obx(() {
          if (checkout.methods.isEmpty) {
            return const Text('Tidak ada metode pembayaran yang tersedia.');
          }

          return Column(
            children: checkout.methods.map((method) {
              final String value = method['value'] ?? '';

              final String label = method['label'] ?? '';

              final bool isSelected = checkout.paymentMethod.value == value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: RadioListTile<String>(
                  activeColor: Colors.green,
                  title: Text(label),
                  value: value,
                  groupValue: checkout.paymentMethod.value,
                  onChanged: checkout.changeMethod,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// PROMO & VOUCHER
// ============================================================================

class _PromoVoucherCard extends StatelessWidget {
  final CheckoutController checkout;
  final int subtotal;
  final List<CartItem> items;

  const _PromoVoucherCard({
    required this.checkout,
    required this.subtotal,
    required this.items,
  });

  String? _priceListId() {
    final id = checkout.selectedPriceListId?.value;

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    final priceListId = _priceListId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====================================================================
        // PROMO
        // ====================================================================
        const Row(
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text(
              "Promo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // --------------------------------------------------------------------
        // STATUS PROMO
        // --------------------------------------------------------------------
        Obx(() {
          if (checkout.promoCodes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                "Pilih promo yang tersedia",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              "${checkout.promoCodes.length} promo diterapkan",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),

        const SizedBox(height: 14),

        // --------------------------------------------------------------------
        // PROMO YANG SUDAH DIPAKAI
        // --------------------------------------------------------------------
        Obx(() {
          if (checkout.promoCodes.isEmpty) {
            return const SizedBox.shrink();
          }

          final appliedPromos = checkout.promotions.where((promo) {
            return checkout.promoCodes.contains(promo.code);
          }).toList();

          if (appliedPromos.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              ...appliedPromos.map((promo) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 20,
                        color: Colors.green,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: "Batalkan promo",
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.redAccent,
                        onPressed: () {
                          checkout.removePromoCode(
                            promo.code,
                            subtotal: subtotal,
                            items: items,
                            priceListId: priceListId,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),

        const SizedBox(height: 6),

        // --------------------------------------------------------------------
        // DROPDOWN PROMO
        // --------------------------------------------------------------------
        Obx(() {
          final availablePromotions = checkout.promotions
              .where((promo) => promo.isValidNow)
              .toList();

          if (availablePromotions.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Belum ada promo yang tersedia.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<PromotionModel>(
                key: ValueKey("promo-dropdown-${checkout.promoCodes.length}"),

                value: null,

                isExpanded: true,

                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.local_offer,
                    color: Colors.green,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                hint: const Text("Pilih Promo"),

                items: availablePromotions.map((promo) {
                  final alreadyApplied = checkout.promoCodes.contains(
                    promo.code,
                  );

                  return DropdownMenuItem<PromotionModel>(
                    value: promo,
                    enabled: !alreadyApplied,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: alreadyApplied
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                onChanged: (promo) {
                  if (promo == null) return;

                  checkout.applySelectedPromotion(
                    promotion: promo,
                    subtotal: subtotal,
                    items: items,
                    priceListId: priceListId,
                  );
                },
              ),
            ],
          );
        }),

        const Divider(height: 24),

        // ====================================================================
        // VOUCHER
        // ====================================================================
        const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green),

            SizedBox(width: 8),

            Text(
              'Voucher',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // --------------------------------------------------------------------
        // INPUT VOUCHER
        // --------------------------------------------------------------------
        _CodeField(
          controller: checkout.voucherController,
          label: 'Kode Voucher',
          hint: 'Contoh: MEMBER10',
          icon: Icons.card_giftcard,
          onApplied: () {
            checkout.applyVoucher(
              subtotal: subtotal,
              items: items,
              priceListId: priceListId,
            );
          },
        ),

        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // VOUCHER YANG SUDAH DIPAKAI
        // --------------------------------------------------------------------
        Obx(() {
          if (checkout.voucherCodes.isEmpty) {
            return const SizedBox.shrink();
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: checkout.voucherCodes.map((code) {
                return InputChip(
                  label: Text(code),

                  deleteIcon: const Icon(Icons.close, size: 18),

                  onDeleted: () {
                    checkout.removeVoucherCode(
                      code,
                      subtotal: subtotal,
                      items: items,
                      priceListId: priceListId,
                    );
                  },
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// CODE FIELD
// ============================================================================

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onApplied;

  const _CodeField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onApplied,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      textCapitalization: TextCapitalization.characters,

      onSubmitted: (_) {
        onApplied();
      },

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        suffixIcon: TextButton(
          onPressed: onApplied,
          child: const Text('Terapkan'),
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final CheckoutController checkout;
  final int subtotal;
  final int total;
  final String Function(int) format;

  const _SummaryCard({
    required this.checkout,
    required this.subtotal,
    required this.total,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff4fbf6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd6eddb)),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', amount: subtotal, format: format),

          _PriceRow(
            label: 'Diskon Promo',
            amount: checkout.promoDiscountAmount.value,
            format: format,
            isDiscount: true,
          ),

          const SizedBox(height: 8),

          _PriceRow(
            label: 'Diskon Voucher',
            amount: checkout.voucherDiscountAmount.value,
            format: format,
            isDiscount: true,
          ),

          const Divider(height: 24, thickness: 1),

          _PriceRow(
            label: 'Total Pembayaran',
            amount: total,
            format: format,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRICE ROW
// ============================================================================

class _PriceRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isTotal;
  final bool isDiscount;
  final String Function(int) format;

  const _PriceRow({
    required this.label,
    required this.amount,
    required this.format,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: isTotal ? 18 : 15,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );

    final amountStyle = TextStyle(
      fontSize: isTotal ? 22 : 15,
      fontWeight: FontWeight.bold,
      color: isTotal
          ? Colors.green
          : isDiscount
          ? Colors.red
          : Colors.black,
    );

    final String displayAmount = isDiscount && amount > 0
        ? '- ${format(amount)}'
        : format(amount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),

        Text(displayAmount, style: amountStyle),
      ],
    );
  }
}

// ============================================================================
// BOTTOM BAR
// ============================================================================

class _BottomBar extends StatelessWidget {
  final int total;
  final String Function(int) format;
  final RxBool isLoading;
  final VoidCallback onPayPressed;

  const _BottomBar({
    required this.total,
    required this.format,
    required this.isLoading,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: const BoxDecoration(
        color: Colors.white,

        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),

      child: SafeArea(
        top: false,

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey)),
                    Text(
                      format(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );

                final paymentButton = SizedBox(
                  height: 50,
                  child: Obx(() {
                    if (isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return AppButton(
                      text: 'Bayar ${format(total)}',
                      onPressed: onPayPressed,
                    );
                  }),
                );

                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      totalInfo,
                      const SizedBox(height: 12),
                      paymentButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: totalInfo),
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: paymentButton),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
