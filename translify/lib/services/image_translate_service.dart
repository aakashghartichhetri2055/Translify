import 'package:http/http.dart' as http;
import 'dart:convert';
import "endpoints.dart";
import "get_token.dart";
import "package:translify/models/image_translation_response_model.dart";

Future<List<ImageTranslationResponseModel>> imageTranslationService(
  String filepath,
  String originalLang,
  String targetLang,
) async {
  String accessToken = await getToken();

  var request = http.MultipartRequest("POST", Endpoints.imageTranslate);
  request.files.add(
    await http.MultipartFile.fromPath(
      "image",
      filepath,
      contentType: http.MediaType("image", "jpeg"),
    ),
  );

  request.headers["Authorization"] = "Bearer $accessToken";

  request.fields["source_language"] = originalLang;
  request.fields["target_language"] = targetLang;

  request.fields["store_history"] = "false";

  http.StreamedResponse response = await request.send();

  var responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(responseBody);

    final result = data
        .map<ImageTranslationResponseModel>(
          (item) => ImageTranslationResponseModel.fromJson(item),
        )
        .toList();

    return result;
  } else {
    throw Exception("Error ${response.statusCode}: $responseBody");
  }
}
