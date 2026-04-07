// A button for the Home View. A user clicks on the button to be taken to the respective feature

import 'package:flutter/material.dart';

/// Feature button widget
/// Parameters
///   VoidCallBack action: the action to take when the button is pressed
///   Icon icon: the icon for the feature
///   String text: the text underneath the icon
///   Color accentColor: the color of the text and icon
///   Color backgroundColor: the color of the background
class FeatureButton extends StatelessWidget {
  final VoidCallback action;
  final IconData icon;
  final String text;
  final Color accentColor;
  final Color backgroundColor;

  const FeatureButton({
    super.key,
    required this.action,
    required this.icon,
    required this.text,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        overlayColor: accentColor,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .5,
        height: MediaQuery.of(context).size.height * .25,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(icon, color: accentColor, size: 100),

            // Text
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
