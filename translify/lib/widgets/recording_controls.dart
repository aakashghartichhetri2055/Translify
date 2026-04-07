// The controls for when there is a recording in process
import 'package:flutter/material.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({
    super.key,
    required this.cancelButtonMessage,
    required this.cancelButtonFunction,
    required this.endButtonMessage,
    required this.endButtonFunction,
    required this.buttonTextColor,
    required this.buttonBackgroundColor,
  });

  final String cancelButtonMessage;
  final VoidCallback cancelButtonFunction;
  final String endButtonMessage;
  final VoidCallback endButtonFunction;

  final Color buttonTextColor;
  final Color buttonBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: MediaQuery.of(context).size.width * .1),

        // The button to cancel the recording
        TextButton(
          onPressed: cancelButtonFunction,
          style: TextButton.styleFrom(
            foregroundColor: buttonTextColor,
            backgroundColor: buttonBackgroundColor,
          ),
          child: Text(cancelButtonMessage),
        ),

        SizedBox(width: MediaQuery.of(context).size.width * .1),

        // The button to end the recording
        TextButton(
          onPressed: endButtonFunction,
          style: TextButton.styleFrom(
            foregroundColor: buttonTextColor,
            backgroundColor: buttonBackgroundColor,
          ),
          child: Text(endButtonMessage),
        ),

        SizedBox(width: MediaQuery.of(context).size.width * .1),
      ],
    );
  }
}
