import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> saveToken(String token) async {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  await storage.write(key: "access_token", value: token);
}
