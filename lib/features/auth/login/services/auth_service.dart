import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      "https://nonflaky-predoubtfully-kayleigh.ngrok-free.dev";

  static Future<Map<String, dynamic>> login({
  required String code,
  required String name,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/api/auth/login"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "code": code,
      "name": name,
    }),
  );

  print("STATUS : ${response.statusCode}");
  print("BODY   : ${response.body}");

  return jsonDecode(response.body);
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
