// The microphone row at the bottom of the Conversation Translation view

import 'package:flutter/material.dart';

class MicrophoneRow extends StatelessWidget {
  const MicrophoneRow({
    super.key,
    required this.primarySpeakerColor,
    required this.primarySpeakerAction,
    required this.secondarySpeakerColor,
    required this.secondarySpeakerAction,
    required this.microphoneIconColor,
  });

  // The parameters for the primary speaker
  final Color primarySpeakerColor;
  final VoidCallback primarySpeakerAction;

  // The parameters for the secondary speaker
  final Color secondarySpeakerColor;
  final VoidCallback secondarySpeakerAction;

  final Color microphoneIconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: MediaQuery.of(context).size.width * .1),
        // The button for the primary speaker
        IconButton.filled(
          icon: Icon(Icons.mic),
          iconSize: 40,
          onPressed: primarySpeakerAction,
          style: IconButton.styleFrom(
            backgroundColor: primarySpeakerColor,
            foregroundColor: microphoneIconColor,
          ),
        ),

        SizedBox(width: MediaQuery.of(context).size.width * .3),

        // The button for the secondary speaker
        IconButton(
          icon: Icon(Icons.mic),
          onPressed: secondarySpeakerAction,
          color: secondarySpeakerColor,
          iconSize: 40,
          style: IconButton.styleFrom(
            backgroundColor: secondarySpeakerColor,
            foregroundColor: microphoneIconColor,
          ),
        ),

        SizedBox(width: MediaQuery.of(context).size.width * .1),
      ],
    );
  }
}
