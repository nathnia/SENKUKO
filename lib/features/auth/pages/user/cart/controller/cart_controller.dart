import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  final String variantId;
  final String priceListId;
  final String? imageUrl;

  int qty;
  bool selected;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.variantId,
    required this.priceListId,

    this.imageUrl,
    this.qty = 1,
    this.selected = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'qty': qty,
    'selected': selected,
    'variantId': variantId,
    'priceListId': priceListId,
    'imageUrl': imageUrl,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      variantId: json['variantId'] ?? '',
      priceListId: json['priceListId'] ?? '',
      imageUrl: json['imageUrl'],
      qty: json['qty'],
      selected: json['selected'],
    );
  }
}

class CartController extends GetxController {
  final box = GetStorage();

  var items = <CartItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCart(); // load saat app dibuka
  }

  // LOAD DATA
  void loadCart() {
    final data = box.read('cart');

    if (data != null) {
      items.value = List<Map<String, dynamic>>.from(
        data,
      ).map((e) => CartItem.fromJson(e)).toList();
    }
  }

  // SAVE DATA
  void saveCart() {
    box.write('cart', items.map((e) => e.toJson()).toList());
  }

  // TAMBAH ITEM
  void addItem(
    String id,
    String name,
    int price,
    String variantId,
    String priceListId,
    String? imageUrl,
  ) {
    int index = items.indexWhere((item) => item.variantId == variantId);

    if (index != -1) {
      items[index].qty++;
    } else {
      items.add(
        CartItem(
          id: id,
          name: name,
          price: price,
          variantId: variantId,
          priceListId: priceListId,
          imageUrl: imageUrl,
        ),
      );
    }

    items.refresh();
    saveCart();
  }

  // TAMBAH QTY
  void increaseQty(int index) {
    items[index].qty++;
    items.refresh();
    saveCart();
  }

  // KURANG QTY
  void decreaseQty(int index) {
    if (items[index].qty > 1) {
      items[index].qty--;
    } else {
      items.removeAt(index);
    }

    items.refresh();
    saveCart();
  }

  // CHECK / UNCHECK
  void toggleItem(int index) {
    items[index].selected = !items[index].selected;
    items.refresh();
    saveCart();
  }

  // SELECT ALL
  void toggleAll(bool value) {
    for (var item in items) {
      print("VARIANT ID: ${item.variantId}");
    }

    items.refresh();
    saveCart();
  }

  // AMBIL ITEM TERPILIH
  List<CartItem> get selectedItems {
    return items.where((item) => item.selected).toList();
  }

  // TOTAL
  int get totalPrice {
    return selectedItems.fold(0, (sum, item) => sum + item.price * item.qty);
  }

  // STATUS SELECT ALL
  bool get isAllSelected {
    if (items.isEmpty) return false;
    return items.every((item) => item.selected);
  }

  // HAPUS ITEM YANG SUDAH DI CHECKOUT
  void removeSelectedItems() {
    items.removeWhere((item) => item.selected);
    items.refresh();
    saveCart();
  }

  // CLEAR SEMUA
  void clearCart() {
    items.clear();
    saveCart();
  }
}
