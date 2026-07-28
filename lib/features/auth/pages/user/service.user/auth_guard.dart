import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/features/auth/login/views/login_page.dart';
import 'user_service.dart';

class AuthGuard {
  static Future<bool> checkUser() async {
    final box = GetStorage();

    final token = box.read("token");

    if (token == null) {
      return false;
    }

    final me = await UserService.getMe(token);

    if (me == null) {
      box.erase();

      Get.offAll(() => LoginPage());

      return false;
    }

    box.write("user", me);

    final status =
        me["status"]
            .toString()
            .toLowerCase();

    if (status != "active") {
      await Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Column(
            children: [
              Icon(
                Icons.block,
                size: 60,
                color: Colors.red,
              ),

              SizedBox(height: 15),

              Text(
                "Akun Dinonaktifkan",
                textAlign: TextAlign.center,
              ),
            ],
          ),

          content: const Text(
            "Akun Anda telah dinonaktifkan oleh admin.\n\nSilakan hubungi admin SENKUKO.",
            textAlign: TextAlign.center,
          ),

          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },

                child: const Text("OK"),
              ),
            ),
          ],
        ),

        barrierDismissible: false,
      );

      box.erase();

      Get.offAll(() => LoginPage());

      return false;
    }

    return true;
  }
}