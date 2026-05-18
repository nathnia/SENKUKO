import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: Column(
          children: [

            const Spacer(),

            //ICON SUCCESS
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),

            const SizedBox(height: 20),

            //TEXT
            const Text(
              "Pesanan Berhasil!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Terima kasih sudah berbelanja",
              style: TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            //BUTTON
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // KE HOME
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offAllNamed('/home'); 
                        // atau:
                        // Get.offAll(() => HomePage());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Kembali ke Beranda"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // LIHAT PESANAN (optional nanti)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // nanti bisa ke order history
                        Get.back();
                      },
                      child: const Text("Lihat Pesanan"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}