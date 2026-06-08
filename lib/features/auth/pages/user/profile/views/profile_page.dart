import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/login/views/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    final user = box.read("user") ?? {};

    final String name = user["name"] ?? "-";
    final String code = user["code"] ?? "-";
    final String status = user["status"] ?? "-";
    final String role = user["role"] ?? "-";
    final String createdAt = user["created_at"] ?? "-";

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(code, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _infoCard(
                icon: Icons.verified_user,
                title: "Status",
                value: status,
              ),

              _infoCard(icon: Icons.badge, title: "Role", value: role),

              _infoCard(
                icon: Icons.calendar_month,
                title: "Terdaftar",
                value: createdAt,
              ),

              const SizedBox(height: 10),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),

                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  onTap: () {
                    Get.defaultDialog(
                      title: "Logout",
                      middleText: "Apakah Anda yakin ingin keluar?",

                      textConfirm: "Ya",
                      textCancel: "Batal",

                      confirmTextColor: Colors.white,

                      onConfirm: () {
                        box.remove("token");
                        box.remove("user");

                        Get.offAll(() => LoginPage());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),

        title: Text(title),

        subtitle: Text(value),
      ),
    );
  }
}
