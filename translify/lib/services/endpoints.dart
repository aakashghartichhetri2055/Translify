class Endpoints {
  static const String base = "blank";
  // 10.0.2.2 is the address used to reach the machine's local host address from the emulated device in android studio
  static Uri me = Uri.parse("$base/me");

  static Uri signUp = Uri.parse("$base/signup");

  static Uri login = Uri.parse("$base/login");

  static Uri speechTranslate = Uri.parse("$base/translate/speech-to-text");

  static Uri imageTranslate = Uri.parse("$base/translate/image-to-text");

  static Uri userHistory = Uri.parse("$base/history");
}
