import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logOutService() async {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  await storage.delete(key: "access_token");
}
