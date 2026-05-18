import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkuko/features/auth/pages/user/main/views/main_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    decoration: InputDecoration(
                      hintText: "Nomor HP / Pelanggan",
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Lupa Password?"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Get.offAll(() => const MainPage());
                      },
                      child: const Text("Masuk"),
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