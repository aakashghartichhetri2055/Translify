class Endpoints {
  static const String base = "http://192.168.1.16:8000";
  // 10.0.2.2 is the address used to reach the machine's local host address from the emulated device in android studio
  static Uri signUp = Uri.parse("$base/signup");

  static Uri login = Uri.parse("$base/login");

  static Uri speechTranslate = Uri.parse("$base/translateSpeech");
}
