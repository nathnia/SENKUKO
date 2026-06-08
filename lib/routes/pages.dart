import 'package:flutter/material.dart';
import 'package:senkuko/features/auth/pages/user/history/views/history_page.dart';
import 'package:senkuko/features/auth/pages/user/main/views/main_page.dart';
import '../features/auth/login/views/login_page.dart';
import 'package:senkuko/features/auth/pages/user/checkout/views/order_succes_page.dart';

class AppPages {
  static const login = '/login';
  static const home = '/home';
  static const orderSuccess = '/order-success';
  static const history = '/history';

  static Map<String, WidgetBuilder> pages = {
    login: (context) => LoginPage(),
    home: (context) => const MainPage(),
    orderSuccess: (context) => const OrderSuccessPage(),
    history: (context) => const HistoryPage(),
  };

  static const productList = '/product-list';
}