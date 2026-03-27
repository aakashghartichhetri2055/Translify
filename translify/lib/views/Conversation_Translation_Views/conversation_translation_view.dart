import 'package:flutter/material.dart';
import 'package:translify/widgets/conversation_speaker_bubble.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';

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
          ],
        ),
      ),
    );
  }
}
