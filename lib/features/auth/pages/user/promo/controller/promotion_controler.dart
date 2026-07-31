import 'package:get/get.dart';
import '../models/promotion_model.dart';
import '../services/promotion_service.dart';

class PromotionController extends GetxController {
  final promotions = <PromotionModel>[].obs;
  final selectedPromotion = Rxn<PromotionModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromotions();
  }

  Future<void> loadPromotions() async {
    try {
      isLoading.value = true;
      final data = await PromotionService.getPromotions();
      promotions.assignAll(data.cast<PromotionModel>());
    } finally {
      isLoading.value = false;
    }
  }

  void selectPromotion(PromotionModel promo) {
    selectedPromotion.value = promo;
  }
  void clearPromotion() {
    selectedPromotion.value = null;
  }
}