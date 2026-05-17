// One of the boxes for detected text in Camera Translation

import 'package:flutter/material.dart';
import 'package:translify/colors/colors.dart';

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
  Color buttonBackgroundColor = const Color.fromARGB(196, 244, 67, 54);
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
            onPressed: () {
              // Show a dialog with the original text and translated text
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: TranslifyColors.backgroundColor,

                    title: Text(
                      "Translation Details",
                      style: TextStyle(color: TranslifyColors.headerTextColor),
                    ),

                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          // Original text stuff
                          Text(
                            "Original:",
                            style: TextStyle(
                              color:
                                  TranslifyColors.cameraTranslationAccentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            widget.originalText,
                            style: TextStyle(
                              color: TranslifyColors.headerTextColor,
                            ),
                          ),

                          SizedBox(height: 12),

                          // Translated text
                          Text(
                            "Translation:",
                            style: TextStyle(
                              color:
                                  TranslifyColors.cameraTranslationAccentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            widget.translatedText,
                            style: TextStyle(
                              color: TranslifyColors.headerTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Button to close the popup
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              TranslifyColors.cameraTranslationAccentColor,
                          foregroundColor: TranslifyColors.darkButtonText,
                        ),
                        child: const Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
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
