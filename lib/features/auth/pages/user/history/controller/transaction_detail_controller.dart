import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/history/services/history_service.dart';

class TransactionDetailController extends GetxController {
  final isLoading = true.obs;
  final detail = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();

    final id = Get.arguments;

    print("==================================");
    print("TRANSACTION DETAIL PAGE");
    print("ARGUMENT = $id");
    print("==================================");

    if (id == null) {
      isLoading.value = false;

      Get.snackbar(
        "Error",
        "ID transaksi tidak ditemukan.",
      );

      return;
    }

    loadDetail(id.toString());
  }

  // ============================================================
  // LOAD DETAIL TRANSAKSI
  // ============================================================

  Future<void> loadDetail(String id) async {
    try {
      isLoading.value = true;

      print("==================================");
      print("LOAD TRANSACTION DETAIL");
      print("ID : $id");
      print("==================================");

      final result = await HistoryService.getTransactionDetail(id);

      print("==================================");
      print("DETAIL RESULT");
      print(result);
      print("==================================");

      if (result == null) {
        Get.snackbar(
          "Error",
          "Data transaksi tidak ditemukan.",
        );

        return;
      }

      detail.value = result;
    } catch (e, stackTrace) {
      print("==================================");
      print("DETAIL ERROR");
      print(e);
      print(stackTrace);
      print("==================================");

      Get.snackbar(
        "Error",
        "Gagal mengambil detail transaksi.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String rupiah(dynamic value) {
    double number = 0;

    if (value != null) {
      number = double.tryParse(value.toString()) ?? 0;
    }

    return "Rp ${number.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => "${m[1]}.",
        )}";
  }

  // ============================================================
  // STATUS TRANSAKSI
  // ============================================================

  String statusText(String status) {
    switch (status.toLowerCase()) {
      case "completed":
      case "paid":
      case "settlement":
      case "capture":
        return "Berhasil";

      case "processing":
        return "Sedang Diproses";

      case "pending":
      case "pending_payment":
        return "Menunggu Konfirmasi";

      case "cancel":
      case "cancelled":
        return "Dibatalkan";

      case "expire":
        return "Kadaluarsa";

      case "deny":
        return "Ditolak";

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS PEMBAYARAN
  // ============================================================

  String paymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return "Sudah Dibayar";

      case "pending":
        return "Belum Dibayar";

      case "cancelled":
      case "cancel":
        return "Dibatalkan";

      case "failed":
        return "Gagal";

      case "expire":
        return "Kadaluarsa";

      default:
        return status;
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(String date) {
    try {
      final d = DateTime.parse(date);

      return "${d.day.toString().padLeft(2, '0')}/"
          "${d.month.toString().padLeft(2, '0')}/"
          "${d.year} "
          "${d.hour.toString().padLeft(2, '0')}:"
          "${d.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return date;
    }
  }

  // ============================================================
  // CEK BOLEH CANCEL ATAU TIDAK
  // ============================================================

  bool get canCancelTransaction {
    final transaction = detail.value;

    if (transaction == null) return false;

    final status = transaction["status"]?.toString().toLowerCase();

    final paymentStatus = transaction["payment_status"]
        ?.toString()
        .toLowerCase();

    return status == "pending_payment" &&
        paymentStatus == "pending";
  }

  // ============================================================
  // CANCEL TRANSACTION
  // ============================================================

  Future<void> cancelTransaction() async {
    final transaction = detail.value;

    if (transaction == null) {
      Get.snackbar(
        "Error",
        "Data transaksi tidak ditemukan.",
      );

      return;
    }

    final transactionId = transaction["id"]?.toString();

    if (transactionId == null || transactionId.isEmpty) {
      Get.snackbar(
        "Error",
        "ID transaksi tidak ditemukan.",
      );

      return;
    }

    if (!canCancelTransaction) {
      Get.snackbar(
        "Tidak Dapat Dibatalkan",
        "Transaksi ini sudah tidak dapat dibatalkan.",
      );

      return;
    }

    try {
      isLoading.value = true;

      final result = await HistoryService.cancelTransaction(
        transactionId,
      );

      if (result == null) {
        Get.snackbar(
          "Gagal",
          "Transaksi tidak dapat dibatalkan.",
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      print("==================================");
      print("CANCEL SUCCESS");
      print(result);
      print("==================================");

      // ============================================================
      // PENTING
      //
      // Jangan langsung:
      //
      // detail.value = result;
      //
      // Karena response cancel hanya data ringkas dan tidak memiliki
      // field items.
      //
      // Kita gabungkan response cancel dengan detail lama.
      // ============================================================

      final currentDetail = Map<String, dynamic>.from(
        detail.value!,
      );

      currentDetail.addAll(result);

      detail.value = currentDetail;

      Get.snackbar(
        "Berhasil",
        "Transaksi berhasil dibatalkan.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      print("==================================");
      print("CANCEL CONTROLLER ERROR");
      print(e);
      print(stackTrace);
      print("==================================");

      Get.snackbar(
        "Error",
        "Terjadi kesalahan saat membatalkan transaksi.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}