// lib/features/auth/pages/user/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:senkuko/core/widgets/app_button.dart';
import 'package:senkuko/core/widgets/app_card.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';

/// ---------------------------------------------------------------------
/// 1️⃣ Checkout Page (Stateful) – menyiapkan data & memanggil preview sekali
/// ---------------------------------------------------------------------
class CheckoutPage extends StatefulWidget {
  /// Jika Checkout dipanggil langsung dari list produk (bukan dari keranjang)
  /// Anda dapat meng‑oper `directItems`. Bila `null`, otomatis pakai
  /// `cart.selectedItems`.
  final List<CartItem>? directItems;

  /// Tandakan `true` bila halaman ini dipanggil dari keranjang, sehingga
  /// proses checkout harus meng‑update status keranjang.
  final bool isFromCart;

  const CheckoutPage({
    Key? key,
    this.directItems,
    this.isFromCart = false,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // -----------------------------------------------------------------
  // Controllers & storage
  // -----------------------------------------------------------------
  final CartController _cart = Get.find<CartController>();
  final CheckoutController _checkout = Get.find<CheckoutController>();
  final GetStorage _store = GetStorage();

  // -----------------------------------------------------------------
  // Data yang akan diproses
  // -----------------------------------------------------------------
  late List<CartItem> _items;
  late int _subtotal;

  // -----------------------------------------------------------------
  // Formatter harga (Rupiah)
  // -----------------------------------------------------------------
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _prepareItems();
    WidgetsBinding.instance.addPostFrameCallback((_) => _previewDiscounts());
  }

  @override
  void didUpdateWidget(covariant CheckoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika parameter berubah (mis. directItems), perbarui data + preview.
    if (oldWidget.directItems != widget.directItems ||
        oldWidget.isFromCart != widget.isFromCart) {
      _prepareItems();
      _previewDiscounts();
    }
  }

  void _prepareItems() {
    _items = widget.directItems ?? _cart.selectedItems;
    _subtotal = _items.fold<int>(0, (s, i) => s + (i.price * i.qty));
  }

  void _previewDiscounts() {
    _checkout.previewDiscounts(
      subtotal: _subtotal,
      items: _items,
      priceListId: _checkout.selectedPriceListId?.value.isNotEmpty == true
          ? _checkout.selectedPriceListId!.value
          : null,
    );
  }

  /// Hitung total yang akan ditampilkan.
  /// Jika controller sudah mengembalikan nilai > 0, gunakan nilai itu,
  /// jika tidak hitung secara manual.
  int _currentTotal() => _checkout.totalPrice.value > 0
      ? _checkout.totalPrice.value
      : _subtotal -
          _checkout.promoDiscountAmount.value -
          _checkout.voucherDiscountAmount.value;

  String _formatRupiah(int price) => _currencyFormatter.format(price);

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------
    // Data user (nama & telepon) – aman bila tidak ada
    // -----------------------------------------------------------------
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
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // 2️⃣ Konten utama (scrollable)
          // -----------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alamat pengiriman -------------------------------------------------
                  _ShippingAddressCard(
                    userName: user['name'] ?? '-',
                    userPhone: user['phone'] ?? '-',
                    checkout: _checkout,
                  ),
                  const SizedBox(height: 12),

                  // Daftar produk -------------------------------------------------------
                  _ProductListCard(items: _items),
                  const SizedBox(height: 12),

                  // Metode pembayaran ---------------------------------------------------
                  _PaymentMethodCard(checkout: _checkout),
                  const SizedBox(height: 12),

                  // Promo & Voucher -------------------------------------------------------
                  _PromoVoucherCard(
                    checkout: _checkout,
                    subtotal: _subtotal,
                    items: _items,
                  ),
                  const SizedBox(height: 12),

                  // Ringkasan harga ------------------------------------------------------
                  _SummaryCard(
                    checkout: _checkout,
                    subtotal: _subtotal,
                    total: _currentTotal(),
                    format: _formatRupiah,
                  ),
                  const SizedBox(height: 100), // beri ruang untuk bottom bar
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // 3️⃣ Bottom bar – total + tombol bayar
          // -----------------------------------------------------------------
          _BottomBar(
            total: _currentTotal(),
            format: _formatRupiah,
            isLoading: _checkout.isLoading,
            onPayPressed: () {
              // Validasi alamat
              if (_checkout.addressController.text.trim().isEmpty) {
                Get.snackbar(
                  'Alamat kosong',
                  'Silakan isi alamat pengiriman.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              _checkout.checkout(
                fromCart: widget.isFromCart,
                items: _items,
                promoCode: _checkout.promoController.text.trim(),
                voucherCode: _checkout.voucherController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4️⃣ Widget: Header dengan ikon (digunakan di beberapa card)
// ---------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
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

// ---------------------------------------------------------------------
// 5️⃣ Card: Alamat Pengiriman
// ---------------------------------------------------------------------
class _ShippingAddressCard extends StatelessWidget {
  final String userName;
  final String userPhone;
  final CheckoutController checkout;

  const _ShippingAddressCard({
    Key? key,
    required this.userName,
    required this.userPhone,
    required this.checkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.location_on, title: 'Alamat Pengiriman'),
          const SizedBox(height: 16),

          // Nama & No. Telepon (dari storage)
          Text(
            userName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(userPhone, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 24),

          // Alamat (readonly / edit)
          Obx(() {
            if (!checkout.isEditingAddress.value) {
              // Tampilkan alamat yang tersimpan
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkout.addressController.text,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => checkout.isEditingAddress.value = true,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              );
            }

            // Mode edit alamat
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
                          checkout.isEditingAddress.value = false;
                          await checkout.loadProfile(); // kembali ke data lama
                        },
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => checkout.isEditingAddress.value = false,
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Catatan untuk kurir (opsional)
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
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 6️⃣ Card: Daftar Produk yang akan dipesan
// ---------------------------------------------------------------------
class _ProductListCard extends StatelessWidget {
  final List<CartItem> items;

  const _ProductListCard({Key? key, required this.items}) : super(key: key);

  String _formatRupiah(int price) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(price);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
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
            ...items.map(_itemTile).toList(),
        ],
      ),
    );
  }

  Widget _itemTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (item.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    item.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
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
}

// ---------------------------------------------------------------------
// 7️⃣ Card: Metode Pembayaran
// ---------------------------------------------------------------------
class _PaymentMethodCard extends StatelessWidget {
  final CheckoutController checkout;

  const _PaymentMethodCard({Key? key, required this.checkout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
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
              children: checkout.methods.map((m) {
                final isSelected = checkout.paymentMethod.value == m['value'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<String>(
                    activeColor: Colors.green,
                    title: Text(m['label']!),
                    value: m['value']!,
                    groupValue: checkout.paymentMethod.value,
                    onChanged: (v) => checkout.changeMethod(v!),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 8️⃣ Card: Promo & Voucher
// ---------------------------------------------------------------------
class _PromoVoucherCard extends StatelessWidget {
  final CheckoutController checkout;
  final int subtotal;
  final List<CartItem> items;

  const _PromoVoucherCard({
    Key? key,
    required this.checkout,
    required this.subtotal,
    required this.items,
  }) : super(key: key);

  /// Mengembalikan `priceListId` bila ada, atau `null`.
  String? _priceListId() {
    final id = checkout.selectedPriceListId?.value;
    return (id != null && id.isNotEmpty) ? id : null;
  }

  @override
  Widget build(BuildContext context) {
    final String? priceListId = _priceListId();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo & Voucher',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // ----- Kode Promo -----
          _CodeField(
            controller: checkout.promoController,
            label: 'Kode Promo',
            hint: 'Contoh: PROMO10',
            icon: Icons.local_offer,
            onApplied: () => checkout.applyPromo(
              subtotal: subtotal,
              items: items,
              priceListId: priceListId,
            ),
          ),
          const SizedBox(height: 12),
          // Daftar promo yang sudah ditambahkan
          Obx(() {
            if (checkout.promoCodes.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: checkout.promoCodes.map((code) {
                return InputChip(
                  label: Text(code),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => checkout.removePromoCode(
                    code,
                    subtotal: subtotal,
                    items: items,
                    priceListId: priceListId,
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 16),

          // ----- Kode Voucher -----
          _CodeField(
            controller: checkout.voucherController,
            label: 'Kode Voucher',
            hint: 'Contoh: VOUCHER50',
            icon: Icons.card_giftcard,
            onApplied: () => checkout.applyVoucher(
              subtotal: subtotal,
              items: items,
              priceListId: priceListId,
            ),
          ),
          const SizedBox(height: 12),
          // Daftar voucher yang sudah ditambahkan
          Obx(() {
            if (checkout.voucherCodes.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: checkout.voucherCodes.map((code) {
                return InputChip(
                  label: Text(code),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => checkout.removeVoucherCode(
                    code,
                    subtotal: subtotal,
                    items: items,
                    priceListId: priceListId,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 9️⃣ Helper: TextField khusus kode promo / voucher dengan tombol “Terapkan”
// ---------------------------------------------------------------------
class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onApplied;

  const _CodeField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onApplied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onSubmitted: (_) => onApplied(),
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

// ---------------------------------------------------------------------
// 10️⃣ Card: Ringkasan Harga (Subtotal, Diskon, Total)
// ---------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final CheckoutController checkout;
  final int subtotal;
  final int total;
  final String Function(int) format;

  const _SummaryCard({
    Key? key,
    required this.checkout,
    required this.subtotal,
    required this.total,
    required this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Diskon promo & voucher bisa berubah, sehingga dibungkus Obx.
    return AppCard(
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', amount: subtotal, format: format),
          const SizedBox(height: 10),
          _PriceRow(label: 'Ongkir', amount: 0, format: format),
          const SizedBox(height: 10),

          // Diskon Promo & Voucher (reactive)
          Obx(() {
            final int promoDisc = checkout.promoDiscountAmount.value;
            final int voucherDisc = checkout.voucherDiscountAmount.value;
            return Column(
              children: [
                _PriceRow(label: 'Diskon Promo', amount: promoDisc, format: format),
                const SizedBox(height: 8),
                _PriceRow(label: 'Diskon Voucher', amount: voucherDisc, format: format),
              ],
            );
          }),

          const Divider(height: 24, thickness: 1),
          _PriceRow(label: 'Total Pembayaran', amount: total, format: format, isTotal: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 11️⃣ Widget kecil untuk menampilkan “label – amount”
// ---------------------------------------------------------------------
class _PriceRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isTotal;
  final String Function(int) format;

  const _PriceRow({
    Key? key,
    required this.label,
    required this.amount,
    required this.format,
    this.isTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = TextStyle(
      fontSize: isTotal ? 18 : 15,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    final TextStyle amountStyle = TextStyle(
      fontSize: isTotal ? 22 : 15,
      fontWeight: FontWeight.bold,
      color: isTotal ? Colors.green : Colors.black,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(format(amount), style: amountStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 12️⃣ Bottom Bar (total + tombol bayar)
// ---------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final int total;
  final String Function(int) format;
  final RxBool isLoading;
  final VoidCallback onPayPressed;

  const _BottomBar({
    Key? key,
    required this.total,
    required this.format,
    required this.isLoading,
    required this.onPayPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // ----- Total -----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey)),
                    Text(
                      format(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // ----- Tombol Bayar -----
              SizedBox(
                width: 170,
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
              ),
            ],
          ),
        ),
      );
}
