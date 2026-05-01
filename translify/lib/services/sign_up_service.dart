import 'package:http/http.dart' as http;
import 'dart:convert';
import "endpoints.dart";

Future<String> signUpService(String email, String password) async {
  final http.Response response = await http.post(
    Endpoints.signUp,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"email": email, "password": password}),
  );

  if (response.statusCode == 200) {
    return "Good";
  } else {
    final error = jsonDecode(response.body);

    throw Exception("Sign Up Service Error: $error");
  }
}
