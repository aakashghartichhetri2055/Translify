import 'package:http/http.dart' as http;
import 'package:translify/services/get_history_setting.dart';
import 'dart:convert';
import "endpoints.dart";
import "get_token.dart";

Future<(String, String)> speechTranslateService(
  String filepath,
  String originalLang,
  String targetLang,
) async {
  String accessToken = await getToken();
  String historySetting = await getHistorySetting();

  var request = http.MultipartRequest("POST", Endpoints.speechTranslate);
  request.files.add(
    await http.MultipartFile.fromPath(
      "recording",
      filepath,
      contentType: http.MediaType("audio", "wav"),
    ),
  );

  request.headers["Authorization"] = "Bearer $accessToken";

  request.fields["source_language"] = originalLang;
  request.fields["target_language"] = targetLang;

  request.fields["store_history"] = historySetting;

  http.StreamedResponse response = await request.send();

  var responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    var data = jsonDecode(responseBody);

    return (data["original_text"] as String, data["translated_text"] as String);
  } else {
    throw Exception("Error ${response.statusCode}: $responseBody");
  }
}
