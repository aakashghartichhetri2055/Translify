// A menu dropdown for when a user needs to select a language

import 'package:flutter/material.dart';
import 'package:translify/languages/languages.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.updateLanguageChoice,
    required this.buttonText,
    required this.buttonBackgroundColor,
    required this.buttonTextColor,
    required this.menuItemBackgroundColor,
    required this.menuItemTextColor,
    required this.currentLanguage,
    required this.disabledColor,
  });

  // Callback function to update the stored value in the View widget
  final ValueChanged<Languages> updateLanguageChoice;

  final String buttonText;
  final String currentLanguage;

  // Colors
  final Color buttonBackgroundColor;
  final Color buttonTextColor;
  final Color menuItemBackgroundColor;
  final Color menuItemTextColor;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      // The menu options
      menuChildren: Languages.values.map((language) {
        {
          return Container(
            color: menuItemBackgroundColor,

            child: MenuItemButton(
              child: Text(
                language.name,
                style: currentLanguage == language.code
                    ? TextStyle(color: disabledColor)
                    : TextStyle(color: menuItemTextColor),
              ),
              //   onPressed: null,
              onPressed: () => {updateLanguageChoice(language)},
            ),
          );
        }
      }).toList(),

      // The button that opens up the menu
      builder: (context, controller, child) {
        return TextButton(
          style: TextButton.styleFrom(backgroundColor: buttonBackgroundColor),
          child: Text(buttonText, style: TextStyle(color: buttonTextColor)),
          onPressed: () {
            controller.open();
          },
        );
      },
    );
  }
}


/// TO DO: update the look of the menu to remove the white padding around it