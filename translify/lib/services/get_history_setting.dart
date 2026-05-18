import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String> getHistorySetting() async {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  String setting = await storage.read(key: "save") ?? "null";
  print(setting);

  return setting;
}
