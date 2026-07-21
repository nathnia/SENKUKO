import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/voucher_model.dart';

class VoucherService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  static Future<List<VoucherModel>> getActiveVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vouchers'),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode != 200) {
        print("Voucher API Error : ${response.statusCode}");
        return [];
      }

      final json = jsonDecode(response.body);

      final List data = json["data"];

      return data
          .map((e) => VoucherModel.fromJson(e))
          .where((e) => e.status.toLowerCase() == "active")
          .toList();
    } catch (e) {
      print("Voucher Error : $e");
      return [];
    }
  }
}