import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/auth_service.dart';
import '../../pages/user/main/views/main_page.dart';

class LoginController extends GetxController {
  final codeController = TextEditingController();
  final nameController = TextEditingController();

  final isLoading = false.obs;

  final box = GetStorage();

  Future<void> login() async {
    try {
      isLoading.value = true;

      print("CODE INPUT : ${codeController.text}");
      print("NAME INPUT : ${nameController.text}");

      final result = await AuthService.login(
        code: codeController.text.trim(),
        name: nameController.text.trim(),
      );

      print("=== LOGIN RESPONSE ===");
      print(result);

      if (result["success"] == true) {
        final token = result["data"]["token"];
        final user = result["data"]["user"];

        print("TOKEN = $token");
        print("USER = $user");

        await box.write("token", token);
        await box.write("user", user);

        print("TOKEN TERSIMPAN = ${box.read("token")}");
        print("USER TERSIMPAN = ${box.read("user")}");

        print("GET STORAGE USER = ${box.read("user")}");

        Get.offAll(() => const MainPage());
      } else {
        Get.snackbar("Login Gagal", result["message"] ?? "Terjadi kesalahan");
      }
    } catch (e) {
      Get.snackbar("Login Gagal", "Terjadi kesalahan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
