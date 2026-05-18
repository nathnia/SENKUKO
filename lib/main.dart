import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/app_theme.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/features/auth/login/views/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  Get.put(CartController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Senkuko",
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}