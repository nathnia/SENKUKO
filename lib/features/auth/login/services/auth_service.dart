import 'dart:convert';
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
}