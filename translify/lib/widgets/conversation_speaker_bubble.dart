// In the Conversation Translation Feature view, a bubble that represents a speaker and their options

import 'package:flutter/material.dart';
import 'package:translify/languages/languages.dart';
import 'language_selector.dart';

class ConversationSpeakerBubble extends StatelessWidget {
  const ConversationSpeakerBubble({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.updateLanguageChoice,
    required this.buttonText,
    required this.buttonBackgroundColor,
    required this.buttonTextColor,
    required this.menuItemBackgroundColor,
    required this.menuItemTextColor,
    required this.currentLanguage,
    required this.disabledColor,
  });

  final String text;
  final Color textColor;
  final Color backgroundColor;

  final ValueChanged<Languages> updateLanguageChoice;
  final String buttonText;
  final Color buttonBackgroundColor;
  final Color buttonTextColor;
  final Color menuItemBackgroundColor;
  final Color menuItemTextColor;

  final String currentLanguage;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),

      height: MediaQuery.of(context).size.height * .3,
      width: MediaQuery.of(context).size.width * .9,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * .05,
          MediaQuery.of(context).size.height * .03,
          0,
          MediaQuery.of(context).size.height * .03,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // The text of the speech
            Text(text, style: TextStyle(color: textColor)),

            // The button to select a langauge
            LanguageSelector(
              updateLanguageChoice: (langauge) => {
                updateLanguageChoice(langauge),
              },
              buttonText: buttonText,
              buttonBackgroundColor: buttonBackgroundColor,
              buttonTextColor: buttonTextColor,
              menuItemBackgroundColor: menuItemBackgroundColor,
              menuItemTextColor: menuItemTextColor,
              currentLanguage: currentLanguage,
              disabledColor: disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
