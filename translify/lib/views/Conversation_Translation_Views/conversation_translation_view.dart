import 'package:flutter/material.dart';
import 'package:translify/widgets/alert.dart';
import 'package:translify/widgets/conversation_speaker_bubble.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/microphone_row.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ConversationTranslationView extends StatefulWidget {
  const ConversationTranslationView({super.key});

  @override
  State<ConversationTranslationView> createState() =>
      _ConversationTranslationViewState();
}

class _ConversationTranslationViewState
    extends State<ConversationTranslationView> {
  // Variables for the first speaker
  String speakerOneCurrentText = "Press the microphone to say something";
  String speakerOneCurrentLanguage = "en";
  String speakerOneCurrentLanguageButtonMessage = "Current Language: English";

  // Variables for the second speaker
  String speakerTwoCurrentText =
      "Press the microphone to say something. This is the second speaker";
  String speakerTwoCurrentLanguage = "es";
  String speakerTwoCurrentLanguageButtonMessage = "Current Language: Spanish";

  // Function for when primary speaker wants to speak
  void primarySpeaking() async {
    // Get the status of the audio recording
    bool? status = await permissionCheck();

    /**
        * PLAN:
        *  Create a widget that shows an indication of audio being recorded, and a button to stop the recording
        *  Set up the recorder object so that it is created when this view is created
        *  Figure out how to do file paths
        *  Make sure to dispose of the recorder object when the view is changed
   */
  }

  @override
  void initState() {
    // Setup recorder object here

    super.initState();
  }

  Future<bool?> permissionCheck() async {
    PermissionStatus status = await Permission.microphone.status;

    // If user has provided permission already
    if (status.isGranted) {
      return true;
    }
    // Else ask user to grant permission
    else if (status.isDenied) {
      // Async call here, if try to use context directly, will throw error
      // Have to store the context in a separate variable, and then check if the widget is mounted
      BuildContext contextCheck = context;
      if (!contextCheck.mounted) return null;

      // Show a dialogue to the user asking for permission here
      final request = await showDialog<bool>(
        context: contextCheck,
        barrierDismissible: false,
        builder: (BuildContext context) => Alert(
          title: "Permission to Use Microphone",
          content:
              "We need access to your microphone in order to enable conversation translation.",
          backgroundColor: TranslifyColors.backgroundColor,
          accentColor: TranslifyColors.convesationTranslationAccentColor,
          contentTextColor: TranslifyColors.headerTextColor,
          buttonTextColor: TranslifyColors.darkButtonText,
          yesButtonText: "Ok",
          noButtonText: "No",
        ),
      );

      // If the user does not grant permission, return false
      // I don't think request can be null here, but check here anyways
      if (request == null || request == false) {
        return false;
      }
      // If user wants to grant permission, give them the OS prompt to grant permission
      else {
        PermissionStatus microphonePermissionAsk = await Permission.microphone
            .request();

        if (microphonePermissionAsk.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    } else if (status.isPermanentlyDenied) {
      BuildContext contextCheck = context;
      if (!contextCheck.mounted) return null;

      // Show a dialogue directing the user to enable the permission in system settings
      final request = await showDialog<bool>(
        context: contextCheck,
        barrierDismissible: false,
        builder: (BuildContext context) => Alert(
          title: "Permission to Use Microphone",
          content:
              "Please grant permission to use the microphone in the system settings. We need access to your microphone in order to enable conversation translation.",
          backgroundColor: TranslifyColors.backgroundColor,
          accentColor: TranslifyColors.convesationTranslationAccentColor,
          contentTextColor: TranslifyColors.headerTextColor,
          buttonTextColor: TranslifyColors.darkButtonText,
          yesButtonText: "Go to system settings",
          noButtonText: "No",
        ),
      );

      // If the user does not press the button to go to system settings, return
      // I don't think request can be null here, but check here anyways
      if (request == null || request == false) {
        return false;
      } else {
        openAppSettings();

        // We do not know the outcome of the user going to system settings, so return false
        // This means the user will have to press the microphone button again, but if they enabled the permission in the settings, then it should be fine
        return false;
      }
    }

    return null;
  }

  void updateSpeakerOneLanguageChoice(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the First person picks Spanish in their menu, First person will have Spanish and Second person will have English
    if (speakerTwoCurrentLanguage == language.code) {
      setState(() {
        speakerTwoCurrentLanguage = speakerOneCurrentLanguage;
        speakerTwoCurrentLanguageButtonMessage =
            speakerOneCurrentLanguageButtonMessage;

        speakerOneCurrentLanguage = language.code;
        speakerOneCurrentLanguageButtonMessage =
            "Current Language: ${language.name}";
      });
    }
    // Else only update the first person
    else {
      setState(() {
        speakerOneCurrentLanguage = language.code;
        speakerOneCurrentLanguageButtonMessage =
            "Current Language: ${language.name}";
      });
    }
  }

  void updateSpeakerTwoLanguageChoice(Languages language) {
    // If the languages for the first and second speaker match, swap them around
    // Ex: First person has English, and Second person has Spanish. If the Second person picks English in their menu, First person will have Spanish and Second person will have English
    if (speakerOneCurrentLanguage == language.code) {
      setState(() {
        speakerOneCurrentLanguage = speakerTwoCurrentLanguage;
        speakerOneCurrentLanguageButtonMessage =
            speakerTwoCurrentLanguageButtonMessage;

        speakerTwoCurrentLanguage = language.code;
        speakerTwoCurrentLanguageButtonMessage =
            "Current Language: ${language.name}";
      });
    }
    // Else only update the second person
    else {
      setState(() {
        speakerTwoCurrentLanguage = language.code;
        speakerTwoCurrentLanguageButtonMessage =
            "Current Language: ${language.name}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The first speaker's bubble
            ConversationSpeakerBubble(
              text: speakerOneCurrentText,
              textColor: TranslifyColors.headerTextColor,
              backgroundColor: TranslifyColors.nonAdminButtonColor,
              updateLanguageChoice: (language) => {
                updateSpeakerOneLanguageChoice(language),
              },
              buttonText: speakerOneCurrentLanguageButtonMessage,
              buttonBackgroundColor:
                  TranslifyColors.convesationTranslationAccentColor,
              buttonTextColor: TranslifyColors.darkButtonText,
              menuItemBackgroundColor: TranslifyColors.nonAdminButtonColor,
              menuItemTextColor:
                  TranslifyColors.convesationTranslationAccentColor,
              currentLanguage: speakerOneCurrentLanguage,
              disabledColor: TranslifyColors.disabledOptionColor,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            // The second speaker's bubble
            ConversationSpeakerBubble(
              text: speakerTwoCurrentText,
              textColor: TranslifyColors.headerTextColor,
              backgroundColor: TranslifyColors.nonAdminButtonColor,
              updateLanguageChoice: (language) => {
                updateSpeakerTwoLanguageChoice(language),
              },
              buttonText: speakerTwoCurrentLanguageButtonMessage,
              buttonBackgroundColor:
                  TranslifyColors.conversationTranslationSecondSpeakerColor,
              buttonTextColor: TranslifyColors.darkButtonText,
              menuItemBackgroundColor: TranslifyColors.nonAdminButtonColor,
              menuItemTextColor:
                  TranslifyColors.conversationTranslationSecondSpeakerColor,
              currentLanguage: speakerTwoCurrentLanguage,
              disabledColor: TranslifyColors.disabledOptionColor,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            MicrophoneRow(
              primarySpeakerColor:
                  TranslifyColors.convesationTranslationAccentColor,
              primarySpeakerAction: primarySpeaking,
              secondarySpeakerColor:
                  TranslifyColors.conversationTranslationSecondSpeakerColor,
              secondarySpeakerAction: () => {},
              microphoneIconColor: TranslifyColors.darkButtonText,
            ),
          ],
        ),
      ),
    );
  }
}
