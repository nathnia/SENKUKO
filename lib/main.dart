import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/app_theme.dart';
import 'package:senkuko/features/auth/pages/user/cart/controller/cart_controller.dart';
import 'package:senkuko/routes/pages.dart';

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
    final box = GetStorage();
    final token = box.read("token");

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: AppPages.pages,
      initialRoute: token != null ? AppPages.home : AppPages.login,
      
      // Handle deep links/webhooks
      onGenerateRoute: (settings) {
        // Handle webhook URLs if needed
        if (settings.name?.startsWith('/webhook') == true) {
          // Handle webhook
          return null; // Let the backend handle it
        }
        return null;
      },
    );
  }
}