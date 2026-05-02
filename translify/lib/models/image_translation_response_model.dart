class ImageTranslationResponseModel {
  final String originalText;
  final String translatedText;
  final int x;
  final int y;
  final int width;
  final int height;

  ImageTranslationResponseModel({
    required this.originalText,
    required this.translatedText,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ImageTranslationResponseModel.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'];

    return ImageTranslationResponseModel(
      originalText: json['text'],
      translatedText: json['translation'],
      x: bbox['x'],
      y: bbox['y'],
      width: bbox['w'],
      height: bbox['h'],
    );
  }

  // Mainly for printing out information
  @override
  String toString() {
    return " ImageTranslationResponseModel(text: $originalText, translation: $translatedText, x position: $x, y position: $y, width: $width, height: $height)";
  }
}
