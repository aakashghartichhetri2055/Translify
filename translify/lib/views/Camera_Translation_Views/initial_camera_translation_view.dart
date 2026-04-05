import 'package:flutter/material.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';
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
  late Future<void> initializeControllerFuture;

  @override
  void initState() {
    initializeCameras();
    super.initState();
  }

  void initializeCameras() async {
    // Get cameras
    final List<CameraDescription> cameraList = await availableCameras();

    // Pick the first camera which is on the back of the phone
    CameraDescription backCamera = cameraList.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    // Create the controller for the camera
    currentCamera = CameraController(backCamera, ResolutionPreset.medium);

    // Save the future
    initializeControllerFuture = currentCamera.initialize();

    // Check to see if the view is still available (ie user has not gone back)
    if (!mounted) return;

    // Save the other variables (also triggers rebuild)
    setState(() {
      cameras = cameraList;
      currentCameraDescription = backCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(currentCamera);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
