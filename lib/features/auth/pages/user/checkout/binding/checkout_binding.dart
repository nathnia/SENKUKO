import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/promo/controller/promotion_controler.dart';
import '../controller/checkout_controller.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckoutController>(() => CheckoutController());
    Get.lazyPut<PromotionController>(() => PromotionController());
  }
}