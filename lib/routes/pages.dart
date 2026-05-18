import 'package:flutter/material.dart';
import 'package:senkuko/features/auth/pages/user/home/views/home_page.dart';
import '../features/auth/login/views/login_page.dart';
import 'package:senkuko/features/auth/pages/user/checkout/views/order_succes_page.dart';

class AppPages {
  static const login = '/login';
  static const home = '/home';
  static const orderSuccess = '/order-success';

  static Map<String, WidgetBuilder> pages = {
    login: (context) => const LoginPage(),
    home: (context) => const HomePage(),
    orderSuccess: (context) => const OrderSuccessPage(),
  };
}