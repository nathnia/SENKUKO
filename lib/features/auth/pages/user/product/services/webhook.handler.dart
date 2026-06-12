import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:senkuko/features/auth/pages/user/history/controller/history_controller.dart';

class WebhookHandler {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.app";

  // Handle Midtrans Webhook
  static Future<void> handleMidtransWebhook(Map<String, dynamic> payload) async {
    try {
      print("========== MIDTRANS WEBHOOK ==========");
      print("PAYLOAD: $payload");
      print("=====================================");

      final transactionId = payload['order_id']?.toString();
      final transactionStatus = payload['transaction_status']?.toString();
      final fraudStatus = payload['fraud_status']?.toString();

      if (transactionId == null) return;

      // Update transaction status in backend
      await _updateTransactionStatus(transactionId, transactionStatus, fraudStatus);

      // Refresh history if user is on history page
      _refreshHistoryIfNeeded();

      // Show notification to user
      _showPaymentNotification(transactionStatus ?? '', transactionId);

    } catch (e) {
      print("Webhook handler error: $e");
    }
  }

  // Update transaction status via API
  static Future<void> _updateTransactionStatus(
    String transactionId,
    String? transactionStatus,
    String? fraudStatus,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read("token");

      // Map Midtrans status to your app status
      final appStatus = _mapMidtransStatus(transactionStatus, fraudStatus);

      final response = await http.post(
        Uri.parse("$baseUrl/api/transactions/$transactionId/webhook"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "status": appStatus,
          "midtrans_status": transactionStatus,
          "fraud_status": fraudStatus,
        }),
      );

      print("Update status response: ${response.statusCode}");
      print("Update status body: ${response.body}");

    } catch (e) {
      print("Update transaction status error: $e");
    }
  }

  // Map Midtrans status to app status
  static String _mapMidtransStatus(String? transactionStatus, String? fraudStatus) {
    if (transactionStatus == null) return "pending";

    switch (transactionStatus.toLowerCase()) {
      case "capture":
      case "settlement":
        return fraudStatus == "accept" ? "paid" : "pending";
      
      case "pending":
        return "pending_payment";
      
      case "deny":
      case "cancel":
      case "expire":
        return transactionStatus.toLowerCase();
      
      case "refund":
      case "partial_refund":
        return "refunded";
      
      default:
        return "pending";
    }
  }

  // Refresh history if user is on history page
  static void _refreshHistoryIfNeeded() {
    try {
      // Check if history controller exists
      final historyController = Get.isRegistered<HistoryController>() 
        ? Get.find<HistoryController>() 
        : null;
      
      if (historyController != null) {
        historyController.loadHistory();
      }
    } catch (e) {
      print("Refresh history error: $e");
    }
  }

  // Show payment notification
  static void _showPaymentNotification(String status, String transactionId) {
    String title = "";
    String message = "";
    Color color = Colors.blue;

    switch (status.toLowerCase()) {
      case "capture":
      case "settlement":
        title = "Pembayaran Berhasil";
        message = "Pembayaran untuk pesanan Anda telah berhasil.";
        color = Colors.green;
        break;
      
      case "deny":
        title = "Pembayaran Ditolak";
        message = "Pembayaran Anda ditolak. Silakan coba metode pembayaran lain.";
        color = Colors.red;
        break;
      
      case "expire":
        title = "Pembayaran Kadaluarsa";
        message = "Batas waktu pembayaran telah habis.";
        color = Colors.orange;
        break;
      
      case "cancel":
        title = "Pembayaran Dibatalkan";
        message = "Pembayaran telah dibatalkan.";
        color = Colors.red;
        break;
    }

    if (title.isNotEmpty) {
      Get.snackbar(
        title,
        message,
        backgroundColor: color.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}