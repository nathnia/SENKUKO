import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/pages/user/checkout/controller/checkout_controller.dart';

void main() {
  group('Checkout discount calculation', () {
    test('applies promo discount from promo code', () {
      final discount = CheckoutController.calculateDiscountAmount('PROMO10', 100000);
      expect(discount, 10000);
    });

    test('applies voucher discount from voucher code', () {
      final discount = CheckoutController.calculateDiscountAmount('VOUCHER50', 100000);
      expect(discount, 50000);
    });

    test('sums discounts for multiple applied codes', () {
      final discount = CheckoutController.calculateDiscountTotal(
        ['PROMO10', 'VOUCHER50'],
        100000,
      );
      expect(discount, 60000);
    });

    test('parses discount percent from promo code with digits', () {
      final discount = CheckoutController.calculateDiscountAmount('PROMO15', 100000);
      expect(discount, 15000);
    });

    test('returns zero for unknown code', () {
      final discount = CheckoutController.calculateDiscountAmount('ABC123', 100000);
      expect(discount, 0);
    });

    test('updates selected payment method when changeMethod is called', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await GetStorage.init();
      Get.testMode = true;
      Get.put(CartController());
      final controller = CheckoutController();
      controller.changeMethod('bank_transfer');
      expect(controller.paymentMethod.value, 'bank_transfer');
    });

    test('hydrates address fields from stored user profile', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await GetStorage.init();
      Get.testMode = true;
      Get.put(CartController());

      final box = GetStorage();
      await box.write('user', {
        'address': 'Jl. Mawar No. 10',
        'city': 'Bandung',
        'region': 'Jawa Barat',
        'subregion': 'Cibeunying',
      });

      final controller = CheckoutController();
      controller.syncProfileToControllers(Map<String, dynamic>.from(box.read('user')));

      expect(controller.addressController.text, 'Jl. Mawar No. 10');
      expect(controller.cityController.text, 'Bandung');
      expect(controller.regionController.text, 'Jawa Barat');
      expect(controller.subregionController.text, 'Cibeunying');
    });
  });
}
