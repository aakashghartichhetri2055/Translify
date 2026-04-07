import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/alert.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionsView extends StatefulWidget {
  const CameraPermissionsView({super.key});

  @override
  State<CameraPermissionsView> createState() => _CameraPermissionsViewState();
}

class _CameraPermissionsViewState extends State<CameraPermissionsView> {
  void buttonPressed(BuildContext context) async {
    // Get the status of the camera permission
    PermissionStatus status = await Permission.microphone.status;

    // Check if context is still valid
    BuildContext contextCheck = context;
    if (!contextCheck.mounted) return null;

    // If granted, move them to the next page
    // Should not be possible to hit this, given that the home view checks for this before pushing this view onto stack?
    if (status.isGranted) {
      context.pushReplacement(AppRoutes.initialCamera);
    }
    // Else if denied, ask for permission through OS prompt
    else if (status.isDenied) {
      PermissionStatus cameraPermissionAsk = await Permission.camera.request();

      if (cameraPermissionAsk.isGranted) {
        // Check if context is still valid
        BuildContext contextCheck = context;
        if (!contextCheck.mounted) return null;

        // If granted, move them to the next page
        if (cameraPermissionAsk.isGranted) {
          context.pushReplacement(AppRoutes.initialCamera);
        }
      } // Else if permanently denied, give an alert asking the user to turn on the permission in system settings
      else if (cameraPermissionAsk.isPermanentlyDenied) {
        // Check if context is still valid
        BuildContext contextCheck = context;
        if (!contextCheck.mounted) return null;

        // Show a dialogue directing the user to enable the permission in system settings
        final request = await showDialog<bool>(
          context: contextCheck,
          barrierDismissible: false,
          builder: (BuildContext context) => Alert(
            title: "Permission to Use Camera",
            content:
                "Please grant permission to use the camera in the system settings. We need access to your camera in order to enable camera translation.",
            backgroundColor: TranslifyColors.backgroundColor,
            accentColor: TranslifyColors.cameraTranslationAccentColor,
            contentTextColor: TranslifyColors.headerTextColor,
            buttonTextColor: TranslifyColors.darkButtonText,
            yesButtonText: "Go to system settings",
            noButtonText: "No",
          ),
        );

        // If the user does not press the button to go to system settings, return
        // I don't think request can be null here, but check here anyways
        if (request == null || request == false) {
          return;
        } else {
          openAppSettings();

          // We do not know the outcome of the user going to system settings, so return false
          // This means the user will have to press the button again, but if they enabled the permission in the settings, then it should be fine
          return;
        }
      } else {
        return null;
      }
    }
    // For some reason, asking through .status does not return the same value as asking through .request()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .2),

          // Lock icon
          Center(
            child: Icon(
              Icons.lock_outline,
              color: TranslifyColors.cameraTranslationAccentColor,
              size: 150,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Explanation of what saving their translations would enable
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * .1,
                0,
                MediaQuery.of(context).size.width * .1,
                0,
              ),
              child: Text(
                "Please allow Translify to access your camera in order to enable camera translation.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TranslifyColors.headerTextColor,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Button to bring up permission choice
          Button(
            action: () => {buttonPressed(context)},
            text: "Enable Camera Permission",
            backgroundColor: TranslifyColors.cameraTranslationAccentColor,
            textColor: TranslifyColors.darkButtonText,
          ),
        ],
      ),
    );
  }
}
