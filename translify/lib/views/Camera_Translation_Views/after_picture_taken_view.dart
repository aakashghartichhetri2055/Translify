import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/language_selector.dart';
import 'package:translify/router/routes.dart';
import 'dart:io';
import 'package:translify/services/image_translate_service.dart';
import "package:translify/models/image_translation_response_model.dart";

class AfterPictureTakenView extends StatefulWidget {
  final String imagePath;
  final String initialSourceLanguage;
  final String initialTargetLanguage;

  const AfterPictureTakenView({
    super.key,
    required this.imagePath,
    required this.initialSourceLanguage,
    required this.initialTargetLanguage,
  });

  @override
  State<AfterPictureTakenView> createState() => _AfterPictureTakenViewState();
}

class _AfterPictureTakenViewState extends State<AfterPictureTakenView> {
  // Set variables to change here

  // Target Language Variables
  late String targetLanguage;
  late String targetLanguageButtonMessage;
  void updateTargetLanguage(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the First person picks Spanish in their menu, First person will have Spanish and Second person will have English
    if (sourceLanguage == language.code) {
      // Get the language value from the enum
      Languages targetName = Languages.values.firstWhere(
        (language) => language.code == targetLanguage,
      );

      setState(() {
        sourceLanguage = targetLanguage;
        sourceLanguageButtonMessage = "Source Language: ${targetName.name}";

        targetLanguage = language.code;
        targetLanguageButtonMessage = "Target Language: ${language.name}";
      });
    }
    // Else only update the first person
    else {
      setState(() {
        targetLanguage = language.code;
        targetLanguageButtonMessage = "Target Language: ${language.name}";
      });
    }
  }

  // Source Language Variables
  late String sourceLanguage;
  late String sourceLanguageButtonMessage;
  void updateSourceLanguage(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the First person picks Spanish in their menu, First person will have Spanish and Second person will have English
    if (targetLanguage == language.code) {
      Languages sourceName = Languages.values.firstWhere(
        (language) => language.code == sourceLanguage,
      );

      setState(() {
        targetLanguage = sourceLanguage;
        targetLanguageButtonMessage = "Target Language: ${sourceName.name}";

        sourceLanguage = language.code;
        sourceLanguageButtonMessage = "Source Language: ${language.name}";
      });
    }
    // Else only update the first person
    else {
      setState(() {
        sourceLanguage = language.code;
        sourceLanguageButtonMessage = "Source Language: ${language.name}";
      });
    }
  }

  void translateButtonPressed(BuildContext context) async {
    List<ImageTranslationResponseModel> response =
        await imageTranslationService(
          widget.imagePath,
          sourceLanguage,
          targetLanguage,
        );

    // Go to the next page
    BuildContext contextCheck = context;

    if (!contextCheck.mounted) {
      return;
    } else {
      context.push(
        AppRoutes.cameraTranslationResult,
        extra: {"path": widget.imagePath, "results": response},
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Find the corresponding langauges from the Language Enum
    Languages targetName = Languages.values.firstWhere(
      (language) => language.code == widget.initialTargetLanguage,
    );

    Languages sourceName = Languages.values.firstWhere(
      (language) => language.code == widget.initialSourceLanguage,
    );

    setState(() {
      targetLanguage = targetName.code;
      targetLanguageButtonMessage = "Target Language: ${targetName.name}";

      sourceLanguage = sourceName.code;
      sourceLanguageButtonMessage = "Source Language: ${sourceName.name}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // Push the replacement back to the camera page
        if (didPop) {
          return;
        } else {
          context.pushReplacement(AppRoutes.initialCamera);
        }
      },
      child: Scaffold(
        backgroundColor: TranslifyColors.backgroundColor,

        body: Column(
          children: [
            // Preview of the image
            SizedBox(
              height: MediaQuery.of(context).size.height * .6,
              width: MediaQuery.of(context).size.width,
              child: Image.file(File(widget.imagePath)),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            // The button to select the source language
            LanguageSelector(
              updateLanguageChoice: (langauge) => {
                updateSourceLanguage(langauge),
              },
              buttonText: sourceLanguageButtonMessage,
              buttonBackgroundColor:
                  TranslifyColors.cameraTranslationAccentColor,
              buttonTextColor: TranslifyColors.darkButtonText,
              menuItemBackgroundColor: TranslifyColors.nonAdminButtonColor,
              menuItemTextColor: TranslifyColors.cameraTranslationAccentColor,
              currentLanguage: sourceLanguage,
              disabledColor: TranslifyColors.disabledOptionColor,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .025),

            // The button to select the target language
            LanguageSelector(
              updateLanguageChoice: (langauge) => {
                updateTargetLanguage(langauge),
              },
              buttonText: targetLanguageButtonMessage,
              buttonBackgroundColor:
                  TranslifyColors.cameraTranslationAccentColor,
              buttonTextColor: TranslifyColors.darkButtonText,
              menuItemBackgroundColor: TranslifyColors.nonAdminButtonColor,
              menuItemTextColor: TranslifyColors.cameraTranslationAccentColor,
              currentLanguage: targetLanguage,
              disabledColor: TranslifyColors.disabledOptionColor,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            // The button to take a picture
            Button(
              text: "Translate!",
              action: () => translateButtonPressed(context),
              backgroundColor: TranslifyColors.cameraTranslationAccentColor,
              textColor: TranslifyColors.darkButtonText,
            ),
          ],
        ),
      ),
    );
  }
}
