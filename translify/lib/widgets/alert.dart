// When we need to ask the user for hardware permissions
import 'package:flutter/material.dart';

class Alert extends StatelessWidget {
  final String title;
  final String content;

  final String yesButtonText;

  final String noButtonText;

  final Color backgroundColor;
  final Color accentColor;
  final Color contentTextColor;
  final Color buttonTextColor;

  const Alert({
    super.key,
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.accentColor,
    required this.contentTextColor,
    required this.buttonTextColor,
    required this.yesButtonText,
    required this.noButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: TextStyle(color: contentTextColor)),
      content: Text(content, style: TextStyle(color: contentTextColor)),
      backgroundColor: backgroundColor,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(backgroundColor: accentColor),
          child: Text(noButtonText, style: TextStyle(color: buttonTextColor)),
        ),

        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(backgroundColor: accentColor),
          child: Text(yesButtonText, style: TextStyle(color: buttonTextColor)),
        ),
      ],
    );
  }
}
