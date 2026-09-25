import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  static Map<String, dynamic> _parseJsonResponse(http.Response response) {
    final trimmedBody = response.body.trim();

    if (trimmedBody.isEmpty) {
      throw const FormatException('Response dari server kosong.');
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Format response tidak sesuai.');
      }
      return decoded;
    } on FormatException {
      final preview = trimmedBody.length > 180 ? '${trimmedBody.substring(0, 180)}...' : trimmedBody;
      throw FormatException(
        'Server mengembalikan response bukan JSON (status ${response.statusCode}). $preview',
      );
    }
  }

  static Future<Map<String, dynamic>> login({
    required String code,
    required String name,
  }) async {
    if (baseUrl.isEmpty) {
      throw const HttpException('BASE_URL belum dikonfigurasi di file .env');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'code': code,
        'name': name,
      }),
    );

    print('STATUS : ${response.statusCode}');
    print('BODY   : ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      final preview = response.body.length > 180
          ? '${response.body.substring(0, 180)}...'
          : response.body;
      throw HttpException(
        'Login gagal. Server mengembalikan status ${response.statusCode}. $preview',
      );
    }

    return _parseJsonResponse(response);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
  try {
    final box = GetStorage();
    final token = box.read("token");

    final response = await http.get(
      Uri.parse("$baseUrl/api/auth/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("GET PROFILE STATUS : ${response.statusCode}");
    print("GET PROFILE BODY : ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        return data["data"];
      }
    }

    return null;
  } catch (e) {
    print(e);
    return null;
  }
}
}
