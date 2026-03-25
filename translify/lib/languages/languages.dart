// A enum to define the availble langauges

enum Languages {
  en("English", "en"),
  es("Spanish", "es");

  const Languages(this.name, this.code);
  final String name;
  final String code;
}
