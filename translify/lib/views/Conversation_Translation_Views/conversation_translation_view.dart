import 'package:flutter/material.dart';
import 'package:translify/widgets/language_selector.dart';
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
  String currentLanguage = "en";
  void updateLanguageChoice(Languages language) {
    print(language.code);
    setState(() {
      currentLanguage = language.code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LanguageSelector(
          updateLanguageChoice: (Languages language) => {
            updateLanguageChoice(language),
          },
          currentLanguage: currentLanguage,
          buttonText: "Language",
          buttonBackgroundColor:
              TranslifyColors.convesationTranslationAccentColor,
          buttonTextColor: TranslifyColors.headerTextColor,
          menuItemBackgroundColor: TranslifyColors.nonAdminButtonColor,
          menuItemTextColor: TranslifyColors.convesationTranslationAccentColor,
          disabledColor: TranslifyColors.disabledOptionColor,
        ),
      ],
    );
  }
}


/* 
1. Create the text widgets, and the mic input widgets
2. Position everything on the screen
3. Figure out the drop down menus for the text widgets
  Also, figure out how to store langauges????
4. Figure out how to record text

*/