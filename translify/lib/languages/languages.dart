// A enum to define the availble langauges

enum Languages {
  en("English", "en"),
  es("Spanish", "es"),
  fr("French", "fr");

  const Languages(this.name, this.code);
  final String name;
  final String code;
}
