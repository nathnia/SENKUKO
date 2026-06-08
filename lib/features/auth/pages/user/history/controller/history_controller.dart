import 'package:get/get.dart';

import '../models/history_model.dart';
import '../services/history_service.dart';

class HistoryController extends GetxController {
  var isLoading = true.obs;

  var transactions = <HistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;

      final result = await HistoryService.getHistory();

      transactions.value =
          result.map((e) => HistoryModel.fromJson(e)).toList();
    } finally {
      isLoading.value = false;
    }
  }
}