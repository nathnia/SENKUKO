import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/login/controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
            ),
            child: const Icon(
              Icons.storefront,
              size: 70,
              color: Colors.white,
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),

              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    "Masuk",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // KODE MEMBER
                  TextField(
                    controller: controller.codeController,

                    decoration: InputDecoration(
                      hintText: "Kode Member",
                      prefixIcon: const Icon(Icons.badge),

                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NAMA MEMBER
                  TextField(
                    controller: controller.nameController,

                    decoration: InputDecoration(
                      hintText: "Nama Member",
                      prefixIcon: const Icon(Icons.person),

                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),


                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor: Colors.white,
                      ),

                      onPressed: () {
                        controller.login();
                      },

                      child: Obx(
                        () => controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Masuk"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}