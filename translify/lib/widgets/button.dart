// Resusable button widget

import 'package:flutter/material.dart';

/// Button Widget
/// Parameters
///   String text: the label for the button
///   VoidCallBack action: the action to occur when the button is pressed
///   Color: the color of the button (defaults to the blue accent of Translify); use Color.fromRGBO(r, g, b, opacity)
class Button extends StatelessWidget {
  final String text;
  final VoidCallback action;
  final Color color;
  const Button({
    super.key,
    required this.text,
    required this.action,
    this.color = const Color.fromRGBO(66, 217, 255, 1),
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(text),
    );
  }
}
