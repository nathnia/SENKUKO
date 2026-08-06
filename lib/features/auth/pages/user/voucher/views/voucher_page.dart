import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';

import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherPage extends StatefulWidget {
  final bool isHome;

  const VoucherPage({super.key, this.isHome = false});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  List<VoucherModel> vouchers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVouchers();
  }

  Future<void> loadVouchers() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final result = await VoucherService.getActiveVouchers();

    if (!mounted) return;

    setState(() {
      vouchers = result;
      isLoading = false;
    });
  }

  Future<void> refreshVouchers() async {
    final result = await VoucherService.getActiveVouchers();

    if (!mounted) return;

    setState(() {
      vouchers = result;
    });
  }

  // ============================================================
  // GROUP VOUCHERS BY PROMOTION
  // ============================================================

  Map<String, List<VoucherModel>> get groupedVouchers {
    final Map<String, List<VoucherModel>> grouped = {};

    for (final voucher in vouchers) {
      final key = voucher.promotionCode.isNotEmpty
          ? voucher.promotionCode
          : voucher.promotionName;

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(voucher);
    }

    return grouped;
  }

  // ============================================================
  // HELPER
  // ============================================================

  String getVoucherIcon(String promotionName) {
    final name = promotionName.toLowerCase();

    if (name.contains("gratis ongkir") ||
        name.contains("ongkir") ||
        name.contains("shipping")) {
      return "🚚";
    }

    if (name.contains("diskon") ||
        name.contains("discount") ||
        name.contains("hemat")) {
      return "💸";
    }

    if (name.contains("cashback")) {
      return "💰";
    }

    if (name.contains("member")) {
      return "⭐";
    }

    return "🎁";
  }

  Color getVoucherColor(String promotionName) {
    final name = promotionName.toLowerCase();

    if (name.contains("gratis ongkir") ||
        name.contains("ongkir") ||
        name.contains("shipping")) {
      return const Color(0xFF2563EB);
    }

    if (name.contains("diskon") ||
        name.contains("discount") ||
        name.contains("hemat")) {
      return const Color(0xFF16A34A);
    }

    if (name.contains("cashback")) {
      return const Color(0xFFF97316);
    }

    if (name.contains("member")) {
      return const Color(0xFF7C3AED);
    }

    return const Color(0xFF0F766E);
  }

  String getPromotionName(List<VoucherModel> promotionVouchers) {
    return promotionVouchers.first.promotionName.isNotEmpty
        ? promotionVouchers.first.promotionName
        : "Voucher Senkuko";
  }

  String getPromotionCode(List<VoucherModel> promotionVouchers) {
    return promotionVouchers.first.promotionCode.isNotEmpty
        ? promotionVouchers.first.promotionCode
        : promotionVouchers.first.code;
  }

  // ============================================================
  // COPY VOUCHER
  // ============================================================

  void copyVoucherCode(String code) {
    Clipboard.setData(ClipboardData(text: code));

    Get.snackbar(
      "Voucher Disalin",
      "Kode $code berhasil disalin",
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================
  // SHOW VOUCHER SELECTION
  // ============================================================

  void showVoucherSelection(List<VoucherModel> promotionVouchers) {
    final promotionName = getPromotionName(promotionVouchers);

    final color = getVoucherColor(promotionName);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),

        decoration: const BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),

        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,

                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Center(
                      child: Text(
                        getVoucherIcon(promotionName),

                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          promotionName,

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "${promotionVouchers.length} voucher tersedia",

                          style: TextStyle(
                            color: Colors.grey.shade600,

                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Pilih voucher",

                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),

              ...promotionVouchers.map((voucher) {
                return _buildVoucherOption(voucher, color);
              }),
            ],
          ),
        ),
      ),

      isScrollControlled: true,
    );
  }

  Widget _buildVoucherOption(VoucherModel voucher, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "KODE VOUCHER",

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  voucher.code,

                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton(
            onPressed: () {
              copyVoucherCode(voucher.code);
            },

            style: OutlinedButton.styleFrom(
              foregroundColor: color,

              side: BorderSide(color: color),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            child: const Text("Salin"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (widget.isHome) {
      return _buildHomeVoucher();
    }

    return _buildFullVoucherPage();
  }

  // ============================================================
  // HOME VOUCHER
  // ============================================================

  Widget _buildHomeVoucher() {
    if (isLoading) {
      return _buildHomeLoading();
    }

    if (groupedVouchers.isEmpty) {
      return _buildHomeEmpty();
    }

    final groups = groupedVouchers.values.toList();

    return RefreshIndicator(
      onRefresh: refreshVouchers,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return _buildHomeVoucherCard(groups[index]);
        },
      ),
    );
  }

  Widget _buildHomeVoucherCard(List<VoucherModel> promotionVouchers) {
    final promotionName = getPromotionName(promotionVouchers);
    final promotionCode = getPromotionCode(promotionVouchers);
    final color = getVoucherColor(promotionName);
    final icon = getVoucherIcon(promotionName);
    final voucherCount = promotionVouchers.length;
    return Container(
      width: 310,

      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(height: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),

                          child: Center(
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 21),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promotionName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 13,
                                  ),

                                  const SizedBox(width: 4),

                                  const Text(
                                    "Voucher Aktif",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PROMO",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  promotionCode,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),

                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Text(
                              "$voucherCount tersedia",

                              style: TextStyle(
                                color: color,

                                fontSize: 10,

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () {
                          showVoucherSelection(promotionVouchers);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        child: const Text(
                          "Lihat Voucher",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildHomeLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          width: 310,
          margin: const EdgeInsets.only(right: 12, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  // ============================================================
  // EMPTY HOME
  // ============================================================

  Widget _buildHomeEmpty() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🎁", style: TextStyle(fontSize: 32)),
            SizedBox(height: 6),
            Text(
              "Belum ada voucher aktif",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FULL VOUCHER PAGE
  // ============================================================

  Widget _buildFullVoucherPage() {
  final groups = groupedVouchers.values.toList();

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),

    appBar: AppBar(
      title: const Text("Voucher Saya"),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    body: RefreshIndicator(
      onRefresh: refreshVouchers,
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : groups.isEmpty
              ? _buildFullEmpty()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFullVoucherCard(groups[index]),
                    );
                  },
                ),
    ),
  );
}

  Widget _buildFullVoucherCard(List<VoucherModel> promotionVouchers) {
    final promotionName = getPromotionName(promotionVouchers);
    final promotionCode = getPromotionCode(promotionVouchers);
    final color = getVoucherColor(promotionName);
    final icon = getVoucherIcon(promotionName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),

        child: Column(
          children: [
            Container(height: 8, color: color),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promotionName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),

                                  child: const Text(
                                    "ACTIVE",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  "${promotionVouchers.length} voucher tersedia",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "KODE PROMO",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 5),

                              Text(
                                promotionCode,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.local_offer_rounded, color: color, size: 24),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 17,
                        color: Colors.grey.shade600,
                      ),

                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          "${promotionVouchers.length} voucher unik tersedia untuk promo ini.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        showVoucherSelection(promotionVouchers);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        "Pilih Voucher",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY FULL PAGE
  // ============================================================

  Widget _buildFullEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🎁", style: TextStyle(fontSize: 56)),
                const SizedBox(height: 18),
                const Text(
                  "Belum Ada Voucher",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Belum ada voucher aktif saat ini.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
