import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/splash_page.dart';
import 'package:senkuko/routes/routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash, 
      page: () => SplashPage()
    ),
  ];
}
