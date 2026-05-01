import 'package:http/http.dart' as http;
import 'dart:convert';
import "endpoints.dart";

Future<(String transcript, String translation)> speechTranslateService(
  String filepath,
  String originalLang,
  String targetLang,
) async {
  var request = http.MultipartRequest("POST", Endpoints.speechTranslate);
  request.files.add(
    await http.MultipartFile.fromPath(
      "file",
      filepath,
      contentType: http.MediaType("audio", "wav"),
    ),
  );

  request.fields["originalLang"] = originalLang;
  request.fields["targetLang"] = targetLang;

  http.StreamedResponse response = await request.send();

  var responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    var data = jsonDecode(responseBody);

    return (data["transcript"] as String, data["translation"] as String);
  } else {
    throw Exception("Error ${response.statusCode}: $responseBody");
  }
}
