import 'package:flutter/material.dart';
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
    PermissionStatus status = await Permission.microphone.status;

    print(status);

    // Either the first time the user has used this feature, or they have denied the permission once before
    if (status.isDenied) {
      print("getting permission");
      // Request the permission from the user
      PermissionStatus request = await Permission.microphone.request();

      // If the user denied the request once
      if (request.isDenied) {
        PermissionStatus secondRequest = await Permission.microphone.request();
        // If they deny at this point, permission is permanently denied
        print(secondRequest);

        if (secondRequest.isPermanentlyDenied) {
          print("HERE!");
          openAppSettings();
        }
      }
      // If the user has denied once before, and now they denied a second time, permission is permanently denied now
      else if (status.isPermanentlyDenied) {
        print("HERE!");
        openAppSettings();
      }
    }
    // User has permanently denied the permission
    else if (status.isPermanentlyDenied) {
      print("HERE!");
      openAppSettings();
    }

    // Do a sanity check here
    PermissionStatus secondStatusCheck = await Permission.microphone.status;

    if (secondStatusCheck.isGranted) {
      // Proceed to the rest of the code here

      /**
       * PLAN:
       *  Create a widget that shows an indication of audio being recorded, and a button to stop the recording
       *  Set up the recorder object so that it is created when this view is created
       *  Figure out how to do file paths
       *  Make sure to dispose of the recorder object when the view is changed
       */
    } else {}
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
