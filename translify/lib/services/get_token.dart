import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String> getToken() async {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  String accessToken = await storage.read(key: "access_token") ?? "null";

  return accessToken;
}
