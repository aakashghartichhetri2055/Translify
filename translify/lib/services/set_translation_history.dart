import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> setTranslationHistory(String value) async {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  await storage.write(key: "save", value: value);
}
