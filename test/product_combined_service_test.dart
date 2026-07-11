import 'package:flutter_test/flutter_test.dart';
import 'package:senkuko/features/auth/pages/user/product/services/product_combined_service.dart';

void main() {
  group('ProductCombinedService', () {
    test('prefers a marked default variant when resolving the base product variant', () {
      final prices = [
        {
          'product_variant_id': 'v1',
          'product_variant_name': 'Beras 1kg',
          'price_list_code': 'NORMAL',
          'price': '12000',
          'price_list_id': 'pl-normal',
          'stock': 5,
          'is_default': false,
        },
        {
          'product_variant_id': 'v2',
          'product_variant_name': 'Beras 1kg',
          'price_list_code': 'NORMAL',
          'price': '12000',
          'price_list_id': 'pl-normal',
          'stock': 20,
          'is_default': true,
        },
      ];

      final baseVariant = ProductCombinedService.resolveBaseVariantEntry(prices, {
        'name': 'Beras',
      });

      expect(baseVariant['product_variant_id'], 'v2');
      expect(baseVariant['stock'], 20);
    });

    test('falls back to the normal price-list variant when no default flag exists', () {
      final prices = [
        {
          'product_variant_id': 'v1',
          'product_variant_name': 'Beras 1kg',
          'price_list_code': 'MEMBER',
          'price': '11000',
          'price_list_id': 'pl-member',
          'stock': 3,
        },
        {
          'product_variant_id': 'v2',
          'product_variant_name': 'Beras 1kg',
          'price_list_code': 'NORMAL',
          'price': '12000',
          'price_list_id': 'pl-normal',
          'stock': 8,
        },
      ];

      final baseVariant = ProductCombinedService.resolveBaseVariantEntry(prices, {
        'name': 'Beras',
      });

      expect(baseVariant['product_variant_id'], 'v2');
      expect(baseVariant['stock'], 8);
    });

    test('uses product id when price entries are keyed by product id', () {
      final product = ProductCombinedService.buildProductUi(
        {
          'id': 'p-100',
          'name': 'Susu UHT',
          'description': 'Minuman',
          'category_name': 'Minuman',
          'images': [],
          'total_stock': 12,
        },
        [
          {
            'product_id': 'p-100',
            'product_variant_id': 'v-100',
            'product_variant_name': 'Susu UHT 1L',
            'price_list_code': 'NORMAL',
            'price': '18000',
            'price_list_id': 'pl-normal',
            'stock': 7,
          },
        ],
      );

      expect(product, isNotNull);
      expect(product!.normalPrice, 18000);
      expect(product.variantName, 'Susu UHT 1L');
    });

    test('builds a home product from a normal price entry', () {
      final product = ProductCombinedService.buildHomeProductUi({
        'product_id': 'p-200',
        'product_name': 'Kopi',
        'product_variant_name': 'Kopi 250g',
        'price_list_code': 'NORMAL',
        'price': '15000',
        'price_list_id': 'pl-normal',
        'stock': 4,
        'category_name': 'Minuman',
      });

      expect(product, isNotNull);
      expect(product!.name, 'Kopi');
      expect(product.normalPrice, 15000);
      expect(product.variantName, 'Kopi 250g');
    });

    test('ignores non-normal price entries for home data', () {
      final product = ProductCombinedService.buildHomeProductUi({
        'product_id': 'p-300',
        'product_name': 'Teh',
        'product_variant_name': 'Teh 1L',
        'price_list_code': 'MEMBER',
        'price': '12000',
        'price_list_id': 'pl-member',
        'stock': 2,
      });

      expect(product, isNull);
    });

    test('creates a product entry even when no price entry matches', () {
      final product = ProductCombinedService.buildProductUi(
        {
          'id': 'p-100',
          'name': 'Susu UHT',
          'description': 'Minuman',
          'category_name': 'Minuman',
          'images': [],
          'total_stock': 12,
        },
        [],
      );

      expect(product, isNotNull);
      expect(product!.name, 'Susu UHT');
      expect(product.stock, 12);
    });
  });
}
