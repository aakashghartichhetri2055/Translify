// One of the boxes for detected text in Camera Translation

import 'package:flutter/material.dart';
import 'package:translify/widgets/button.dart';

class CameraTranslationBoundingBox extends StatefulWidget {
  final double x;
  final double y;
  final double width;
  final double height;

  final String originalText;
  final String translatedText;

  const CameraTranslationBoundingBox({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.originalText,
    required this.translatedText,
  });

  @override
  State<CameraTranslationBoundingBox> createState() =>
      _CameraTranslationBoundingBoxState();
}

class _CameraTranslationBoundingBoxState
    extends State<CameraTranslationBoundingBox> {
  // Define the current colors
  Color buttonBackgroundColor = Colors.red;
  Color textColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.x,
      top: widget.y,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: FilledButton(
            onPressed: () => print(
              "Original: ${widget.originalText}. Translation: ${widget.translatedText}",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackgroundColor,
              overlayColor: null,
              minimumSize: Size.fromWidth(double.infinity),
            ),
            child: Text(
              widget.translatedText,
              style: TextStyle(color: textColor, fontSize: 40),
            ),
          ),
        ),
      ),
    );
  }
}
