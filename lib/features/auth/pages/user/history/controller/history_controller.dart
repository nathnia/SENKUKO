<<<<<<< HEAD
// lib/features/auth/pages/user/history/controller/history_controller.dart
=======
>>>>>>> 91feacdad12edb33c77b6e98838a4c3295e044d0
import 'dart:async';
import 'package:get/get.dart';
import '../models/history_model.dart';
import '../services/history_service.dart';

class HistoryController extends GetxController {
  var isLoading = true.obs;
  var transactions = <HistoryModel>[].obs;
  var lastRefreshTime = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;

      final result = await HistoryService.getHistory();

      print("========== PROCESSING TRANSACTIONS ==========");
      print("Total transactions: ${result.length}");

      final List<HistoryModel> parsedTransactions = [];

      for (int i = 0; i < result.length; i++) {
        try {
          final transaction = result[i];
          print("Processing transaction $i: ${transaction["invoice_number"]}");

          // Tambah ini untuk debug tipe data
          transaction.forEach((key, value) {
            print("  $key: ${value.runtimeType} = $value");
          });

          final historyModel = HistoryModel.fromJson(transaction);
          parsedTransactions.add(historyModel);
        } catch (e) {
          print("Error parsing transaction $i: $e");
          print("Transaction data: ${result[i]}");
          continue;
        }
      }

      transactions.value = parsedTransactions;
      lastRefreshTime.value = DateTime.now();

      print("Successfully loaded ${parsedTransactions.length} transactions");
    } catch (e, stackTrace) {
      print("Load history error: $e");
      print("Stack trace: $stackTrace");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }

  // ✅ TAMBAHKAN GETTER INI:
  bool get hasPendingTransactions {
    return transactions.any(
      (trx) =>
          trx.status.toLowerCase() == 'pending' ||
          trx.status.toLowerCase() == 'pending_payment',
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 91feacdad12edb33c77b6e98838a4c3295e044d0
