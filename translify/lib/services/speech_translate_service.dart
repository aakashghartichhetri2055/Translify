import 'package:http/http.dart' as http;
import 'dart:convert';
import "endpoints.dart";
import "get_token.dart";

Future<(String, String)> speechTranslateService(
  String filepath,
  String originalLang,
  String targetLang,
) async {
  String access_token = await getToken();

  var request = http.MultipartRequest("POST", Endpoints.speechTranslate);
  request.files.add(
    await http.MultipartFile.fromPath(
      "recording",
      filepath,
      contentType: http.MediaType("audio", "wav"),
    ),
  );

  request.headers["Authorization"] = "Bearer $access_token";

  request.fields["source_language"] = originalLang;
  request.fields["target_language"] = targetLang;

  request.fields["store_history"] = "false";

  http.StreamedResponse response = await request.send();

  var responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    var data = jsonDecode(responseBody);

    return (data["original_text"] as String, data["translated_text"] as String);
  } else {
    throw Exception("Error ${response.statusCode}: $responseBody");
  }
}
