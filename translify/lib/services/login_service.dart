import 'package:http/http.dart' as http;
import 'dart:convert';
import 'save_token.dart';
import "endpoints.dart";

Future<bool> loginService(String email, String password) async {
  final http.Response response = await http.post(
    Endpoints.login,
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'username': email, 'password': password},
  );

  if (response.statusCode == 200) {
    // Save the token
    final data = jsonDecode(response.body);
    final token = data['access_token'];
    await saveToken(token);

    return true;
  } else {
    final error = jsonDecode(response.body);
    throw Exception("Login Service Error: $error");
  }
}
