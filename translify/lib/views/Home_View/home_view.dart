import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/feature_button.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void settingsButtonTapped(BuildContext context) {
    // Nav to settings page
  }

  void cameraTranslationButtonTapped(BuildContext context) {
    // Nav to camera translation page
  }

  void conversationTranslationButtonTapped(BuildContext context) {
    // Nav to conversation translation page
    context.push(AppRoutes.conversation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // The settings icon button
          Align(
            alignment: AlignmentGeometry.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * .01,
                0,
                0,
                0,
              ),
              child: IconButton(
                onPressed: () => {settingsButtonTapped(context)},
                icon: Icon(
                  Icons.settings,
                  color: TranslifyColors.adminButtonColor,
                ),
                iconSize: 50,
                splashColor: TranslifyColors.adminButtonColor,
              ),
            ),
          ),

          // Button to take you to camera translation feature
          Align(
            alignment: AlignmentGeometry.center,
            child: FeatureButton(
              action: () => {cameraTranslationButtonTapped(context)},
              icon: Icons.photo_camera_outlined,
              text: "Camera Translation",
              accentColor: TranslifyColors.cameraTranslationAccentColor,
              backgroundColor: TranslifyColors.nonAdminButtonColor,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to take you to camera translation feature
          Align(
            alignment: AlignmentGeometry.center,
            child: FeatureButton(
              action: () => {conversationTranslationButtonTapped(context)},
              icon: Icons.mic_none_rounded,
              text: "Conversation Translation",
              accentColor: TranslifyColors.convesationTranslationAccentColor,
              backgroundColor: TranslifyColors.nonAdminButtonColor,
            ),
          ),
        ],
      ),
    );
  }
}
