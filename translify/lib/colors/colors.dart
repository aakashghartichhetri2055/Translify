// A class of the color scheme that Translify uses
// Will be in style of: ui part -> color it should be
//    EX: background -> black
// This way, colors can be changed only here, and are reflected across the entire app

// NOTES:
//    Everything is defined as final instead of const for future features, like a light mode
//    Although I think this way of doing things is not the standard for flutter?

import 'package:flutter/material.dart';

class TranslifyColors {
  /// Color of the app background
  static final backgroundColor = Color.fromRGBO(15, 15, 15, 1);

  /// Color of the Headers / Overall Text
  /// EX: The Translify logo on the Login view, the disclaimer text on the After New User view
  static final headerTextColor = Colors.white;

  /// Color of the buttons that do administrative actions
  /// EX: Login Button, Sign Up Button, the buttons in the Settings views, the gear Icon on the Homepage
  /// Can also be thought of as the accent color of the administrative stuff
  static final adminButtonColor = Color.fromRGBO(66, 217, 255, 1);

  /// Color of the text on the above admin button
  static final adminButtonTextColor = Colors.black;

  /// The accent color for the camera translation
  /// To be used everywhere for camera translation feature
  static final cameraTranslationAccentColor = Color.fromRGBO(255, 77, 77, 1);

  /// The accent color for the conversation translation
  /// To be used when discussing the conversation translation, and when in conversation translation mode, is the color of the primary speaker
  static final convesationTranslationAccentColor = Color.fromRGBO(
    77,
    255,
    188,
    1,
  );

  /// The color for the secondary speaker when in conversation translation mode
  static final conversationTranslationSecondSpeakerColor = Color.fromRGBO(
    184,
    6,
    194,
    1,
  );

  /// The background color for the text inputs
  static final textInputBackgroundColor = Color.fromRGBO(96, 92, 92, 1);

  /// The color used to accent the text inputs
  /// For the label, hint color, border color, etc
  static final textInputAccentColor = Colors.white;

  /// Color of the buttons that don't do administrative stuff
  ///   EX: The two buttons on the homepage for the two translation features
  static final nonAdminButtonColor = Color.fromRGBO(96, 92, 92, 1);

  /// Color of when an option is disabled
  static final disabledOptionColor = Color.fromRGBO(245, 245, 245, 0.338);
}
