import 'package:flutter/material.dart';
import 'dart:io';
import 'package:translify/colors/colors.dart';
import "package:translify/models/image_translation_response_model.dart";
import 'package:translify/widgets/camera_translation_bounding_box.dart';

class CameraTranslationResult extends StatefulWidget {
  final String imagePath;
  final List<ImageTranslationResponseModel> detectedText;

  const CameraTranslationResult({
    super.key,
    required this.imagePath,
    required this.detectedText,
  });

  @override
  State<CameraTranslationResult> createState() =>
      _CameraTranslationResultState();
}

class _CameraTranslationResultState extends State<CameraTranslationResult> {
  // The original dimensions of the image
  double? imageWidth;
  double? imageHeight;

  // Function to get the original dimensions of the image
  Future<void> getImageDimensions() async {
    final image = await decodeImageFromList(
      File(widget.imagePath).readAsBytesSync(),
    );

    setState(() {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    });
  }

  @override
  void initState() {
    super.initState();
    getImageDimensions();
  }

  @override
  Widget build(BuildContext context) {
    if (imageWidth == null || imageHeight == null) {
      return CircularProgressIndicator(
        color: TranslifyColors.cameraTranslationAccentColor,
      );
    } else {
      return Scaffold(
        backgroundColor: TranslifyColors.backgroundColor,
        body: Center(
          // This widget scales everything to the screen size automatically
          child: FittedBox(
            fit: BoxFit.contain,
            // Set the size of the box to the original image dimensions
            // This way, we can directly use the original x and y positions since Stack uses the dimensions of the parent widget for positioning
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Stack(
                children: [
                  Image.file(File(widget.imagePath)),

                  ...widget.detectedText.map((
                    ImageTranslationResponseModel boundingBox,
                  ) {
                    return CameraTranslationBoundingBox(
                      x: boundingBox.x.toDouble(),
                      y: boundingBox.y.toDouble(),
                      width: boundingBox.width.toDouble(),
                      height: boundingBox.height.toDouble(),
                      originalText: boundingBox.originalText,
                      translatedText: boundingBox.translatedText,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
