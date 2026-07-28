import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UserService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  static Future<Map<String, dynamic>?> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);

      if (json["success"] == true) {
        return json["data"];
      }

      return null;
    } catch (e) {
      print("GET ME ERROR : $e");
      return null;
    }
  }
}