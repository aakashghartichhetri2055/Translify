import 'package:flutter/material.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/language_selector.dart';
import 'package:camera/camera.dart';

class InitialCameraTranslationView extends StatefulWidget {
  const InitialCameraTranslationView({super.key});

  @override
  State<InitialCameraTranslationView> createState() =>
      _InitialCameraTranslationViewState();
}

class _InitialCameraTranslationViewState
    extends State<InitialCameraTranslationView> {
  // Camera list
  late final List<CameraDescription> cameras;

  // The current camera being used
  late CameraDescription currentCameraDescription;

  // The controller for the current camera
  late CameraController currentCamera;

  // The future to control the widget building based on status of controller
  Future<void>? initializeControllerFuture;

  void initializeCameras() async {
    // Get cameras
    final List<CameraDescription> cameraList = await availableCameras();

    // Pick the first camera which is on the back of the phone
    CameraDescription backCamera = cameraList.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    // Create the controller for the camera
    currentCamera = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // Save the future
    initializeControllerFuture = currentCamera.initialize();

    // Wait until camera is initialized
    await initializeControllerFuture;

    // Check to see if the view is still available (ie user has not gone back)
    if (!mounted) return;

    // Get the zoom variables
    double min = await currentCamera.getMinZoomLevel();
    double max = await currentCamera.getMaxZoomLevel();

    // Save the other variables (also triggers rebuild)
    setState(() {
      cameras = cameraList;
      currentCameraDescription = backCamera;
      minZoom = min;
      maxZoom = max;
    });
  }

  // Variables to control the zoom
  late final double minZoom;
  late final double maxZoom;
  double currentZoom = 1;
  double baseZoom = 1;

  void captureButtonPressed() async {
    // Ensure camera is available
    await initializeControllerFuture;

    // Take the picture
    final XFile picture = await currentCamera.takePicture();

    print(picture.path);
  }

  // Target Language Variables
  String targetLanguage = "en";
  String targetLanguageButtonMessage = "Current Language: English";
  void updateTargetLanguage(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the First person picks Spanish in their menu, First person will have Spanish and Second person will have English
    if (sourceLanguage == language.code) {
      setState(() {
        sourceLanguage = targetLanguage;
        sourceLanguageButtonMessage = targetLanguageButtonMessage;

        targetLanguage = language.code;
        targetLanguageButtonMessage = "Current Language: ${language.name}";
      });
    }
    // Else only update the first person
    else {
      setState(() {
        targetLanguage = language.code;
        targetLanguageButtonMessage = "Current Language: ${language.name}";
      });
    }
  }

  // Source Language Variables
  String sourceLanguage = "es";
  String sourceLanguageButtonMessage = "Current Language: Spanish";
  void updateSourceLanguage(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the First person picks Spanish in their menu, First person will have Spanish and Second person will have English
    if (targetLanguage == language.code) {
      setState(() {
        targetLanguage = sourceLanguage;
        targetLanguageButtonMessage = sourceLanguageButtonMessage;

        sourceLanguage = language.code;
        sourceLanguageButtonMessage = "Current Language: ${language.name}";
      });
    }
    // Else only update the first person
    else {
      setState(() {
        sourceLanguage = language.code;
        sourceLanguageButtonMessage = "Current Language: ${language.name}";
      });
    }
  }

  @override
  void initState() {
    initializeCameras();
    super.initState();
  }

  @override
  void dispose() {
    currentCamera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: initializeControllerFuture == null
          ? Center(
              child: CircularProgressIndicator(
                color:
                    TranslifyColors.conversationTranslationSecondSpeakerColor,
              ),
            )
          : FutureBuilder<void>(
              future: initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      // The camera view wrapped in gesture dectector for zoom
                      GestureDetector(
                        onScaleStart: (details) {
                          // Save the old zoom value
                          baseZoom = currentZoom;
                        },
                        onScaleUpdate: (details) async {
                          // Figure out the new zoom value for the camera
                          double zoom = (baseZoom * details.scale).clamp(
                            minZoom,
                            maxZoom,
                          );

                          // Set the zoom on the camera
                          await currentCamera.setZoomLevel(zoom);

                          // Save the new zoom value
                          setState(() {
                            currentZoom = zoom;
                          });
                        },
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * .6,
                          width: MediaQuery.of(context).size.width,
                          child: CameraPreview(currentCamera),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * .05,
                      ),

                      // The button to select the target language
                      LanguageSelector(
                        updateLanguageChoice: (langauge) => {
                          updateTargetLanguage(langauge),
                        },
                        buttonText: targetLanguageButtonMessage,
                        buttonBackgroundColor:
                            TranslifyColors.cameraTranslationAccentColor,
                        buttonTextColor: TranslifyColors.darkButtonText,
                        menuItemBackgroundColor:
                            TranslifyColors.nonAdminButtonColor,
                        menuItemTextColor:
                            TranslifyColors.cameraTranslationAccentColor,
                        currentLanguage: targetLanguage,
                        disabledColor: TranslifyColors.disabledOptionColor,
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * .025,
                      ),

                      // The button to select the source language
                      LanguageSelector(
                        updateLanguageChoice: (langauge) => {
                          updateSourceLanguage(langauge),
                        },
                        buttonText: sourceLanguageButtonMessage,
                        buttonBackgroundColor:
                            TranslifyColors.cameraTranslationAccentColor,
                        buttonTextColor: TranslifyColors.darkButtonText,
                        menuItemBackgroundColor:
                            TranslifyColors.nonAdminButtonColor,
                        menuItemTextColor:
                            TranslifyColors.cameraTranslationAccentColor,
                        currentLanguage: sourceLanguage,
                        disabledColor: TranslifyColors.disabledOptionColor,
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * .05,
                      ),

                      // The button to take a picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TranslifyColors.cameraTranslationAccentColor,
                            width: 2,
                          ),
                        ),

                        child: IconButton(
                          onPressed: captureButtonPressed,
                          icon: Icon(Icons.radio_button_checked, size: 50),
                          style: IconButton.styleFrom(
                            backgroundColor: TranslifyColors.backgroundColor,
                            foregroundColor:
                                TranslifyColors.cameraTranslationAccentColor,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: TranslifyColors.cameraTranslationAccentColor,
                    ),
                  );
                }
              },
            ),
    );
  }
}
