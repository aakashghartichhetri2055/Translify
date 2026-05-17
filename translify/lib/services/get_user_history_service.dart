import 'package:http/http.dart' as http;
import 'dart:convert';
import "endpoints.dart";
import "get_token.dart";

Future<List<dynamic>> getUserHistoryService() async {
  String accessToken = await getToken();

  final response = await http.get(
    Endpoints.userHistory,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    return data["items"];
  } else {
    throw Exception("Error ${response.statusCode}: ${response.body}");
  }
}
