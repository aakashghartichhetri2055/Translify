import 'package:http/http.dart' as http;
import "endpoints.dart";
import "get_token.dart";

Future<bool> getUserStatus() async {
  String accessToken = await getToken();

  if (accessToken == "null") {
    return false;
  }

  final response = await http.get(
    Endpoints.me,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}
