import 'dart:io';

import 'package:flutter/material.dart';
import 'package:translify/services/speech_translate_service.dart';
import 'package:translify/widgets/alert.dart';
import 'package:translify/widgets/conversation_speaker_bubble.dart';
import 'package:translify/languages/languages.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/microphone_row.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:translify/widgets/recording_controls.dart';

class ConversationTranslationView extends StatefulWidget {
  const ConversationTranslationView({super.key});

  @override
  State<ConversationTranslationView> createState() =>
      _ConversationTranslationViewState();
}

class _ConversationTranslationViewState
    extends State<ConversationTranslationView> {
  // Variables to control the UI flash duration when a translation is received
  Duration lengthOfColorSwapAnimation = Duration(
    milliseconds: 400,
  ); // When the color changes, the peroid of time the animation of the switch plays for
  Duration durationBeforeSwitchingBack = Duration(
    milliseconds: 400,
  ); // After the color has changed, how long to wait for before it switches back to the normal color

  // Variables for the first speaker
  String speakerOneCurrentText = "Press the microphone to say something";
  String speakerOneCurrentLanguage = "en";
  String speakerOneCurrentLanguageButtonMessage = "Current Language: English";
  Color speakerOneBoxColor = TranslifyColors.nonAdminButtonColor;

  // A function to show the UI has updated through a flash of color
  Future<void> speakerOneFlash() async {
    // Change the color
    setState(() {
      speakerOneBoxColor =
          TranslifyColors.conversationTranslationSecondSpeakerColor;
    });

    // Wait a bit
    await Future.delayed(durationBeforeSwitchingBack);

    // Change the color back
    setState(() {
      speakerOneBoxColor = TranslifyColors.nonAdminButtonColor;
    });
  }

  // Variables for the second speaker
  String speakerTwoCurrentText =
      "Press the microphone to say something. This is the second speaker";
  String speakerTwoCurrentLanguage = "es";
  String speakerTwoCurrentLanguageButtonMessage = "Current Language: Spanish";
  Color speakerTwoBoxColor = TranslifyColors.nonAdminButtonColor;

  Future<void> speakerTwoFlash() async {
    // Change the color
    setState(() {
      speakerTwoBoxColor =
          TranslifyColors.conversationTranslationSecondSpeakerColor;
    });

    // Wait a bit
    await Future.delayed(durationBeforeSwitchingBack);

    // Change the color back
    setState(() {
      speakerTwoBoxColor = TranslifyColors.nonAdminButtonColor;
    });
  }

  // Recorder object
  late final AudioRecorder recorder;

  // Variable to see if recording
  bool recording = false;
  String? currentSpeaker;

  @override
  void initState() {
    // Setup recorder object here
    recorder = AudioRecorder();
    super.initState();
  }

  @override
  void dispose() {
    // Dispose the recorder object here
    recorder.dispose();
    super.dispose();
  }

  // Function for when someone is starting to record
  void startRecording(String speaker) async {
    // Get the status of the audio recording
    bool? status = await permissionCheck();

    if (status == null || status == false) {
      return;
    }

    // Proceed with the recording

    // Get the path to store the output in
    String currentTimestamp = (DateTime.now().millisecondsSinceEpoch)
        .toString();

    Directory fileDirctory = await getApplicationDocumentsDirectory();

    String filePath = '${fileDirctory.path}/${currentTimestamp}aaa.wav';

    setState(() {
      recording = true;
      currentSpeaker = speaker;
    });

    // Start recording
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
  }

  // Function for when the recording is cancelled
  void cancelRecording() async {
    await recorder.cancel();
    setState(() {
      recording = false;
      currentSpeaker = null;
    });
  }

  // Function for when the recording is finished
  void endRecording() async {
    // Stop the recording
    final String? filePath = await recorder.stop();

    // Debug: See that the file actually exists:
    //  File recordedFile = File(filePath!);
    //  bool exists = await recordedFile.exists();
    //  print(exists);
    // But how to access the actual file?

    String source = "";
    String target = "";

    if (currentSpeaker == "primary") {
      source = speakerOneCurrentLanguage;
      target = speakerTwoCurrentLanguage;
    } else if (currentSpeaker == "secondary") {
      source = speakerTwoCurrentLanguage;
      target = speakerOneCurrentLanguage;
    }

    // Begin the process of sending the recording to the backend here
    (String, String) response = await speechTranslateService(
      filePath!,
      source,
      target,
    );

    print(response);

    if (currentSpeaker == "primary") {
      setState(() {
        speakerOneCurrentText = response.$1;
        speakerTwoCurrentText = response.$2;
      });
      await speakerTwoFlash();
    } else if (currentSpeaker == "secondary") {
      setState(() {
        speakerOneCurrentText = response.$2;
        speakerTwoCurrentText = response.$1;
      });
      await speakerOneFlash();
    }

    setState(() {
      recording = false;
      currentSpeaker = null;
    });
  }

  Future<bool?> permissionCheck() async {
    PermissionStatus status = await Permission.microphone.status;

    // If user has provided permission already
    if (status.isGranted) {
      return true;
    }
    // Else ask user to grant permission
    else if (status.isDenied) {
      // Async call here, if try to use context directly, will throw error
      // Have to store the context in a separate variable, and then check if the widget is mounted
      BuildContext contextCheck = context;
      if (!contextCheck.mounted) return null;

      // Show a dialogue to the user asking for permission here
      final request = await showDialog<bool>(
        context: contextCheck,
        barrierDismissible: false,
        builder: (BuildContext context) => Alert(
          title: "Permission to Use Microphone",
          content:
              "We need access to your microphone in order to enable conversation translation.",
          backgroundColor: TranslifyColors.backgroundColor,
          accentColor: TranslifyColors.convesationTranslationAccentColor,
          contentTextColor: TranslifyColors.headerTextColor,
          buttonTextColor: TranslifyColors.darkButtonText,
          yesButtonText: "Ok",
          noButtonText: "No",
        ),
      );

      // If the user does not grant permission, return false
      // I don't think request can be null here, but check here anyways
      if (request == null || request == false) {
        return false;
      }
      // If user wants to grant permission, give them the OS prompt to grant permission
      else {
        PermissionStatus microphonePermissionAsk = await Permission.microphone
            .request();

        if (microphonePermissionAsk.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    } else if (status.isPermanentlyDenied) {
      BuildContext contextCheck = context;
      if (!contextCheck.mounted) return null;

      // Show a dialogue directing the user to enable the permission in system settings
      final request = await showDialog<bool>(
        context: contextCheck,
        barrierDismissible: false,
        builder: (BuildContext context) => Alert(
          title: "Permission to Use Microphone",
          content:
              "Please grant permission to use the microphone in the system settings. We need access to your microphone in order to enable conversation translation.",
          backgroundColor: TranslifyColors.backgroundColor,
          accentColor: TranslifyColors.convesationTranslationAccentColor,
          contentTextColor: TranslifyColors.headerTextColor,
          buttonTextColor: TranslifyColors.darkButtonText,
          yesButtonText: "Go to system settings",
          noButtonText: "No",
        ),
      );

      // If the user does not press the button to go to system settings, return
      // I don't think request can be null here, but check here anyways
      if (request == null || request == false) {
        return false;
      } else {
        openAppSettings();

        // We do not know the outcome of the user going to system settings, so return false
        // This means the user will have to press the microphone button again, but if they enabled the permission in the settings, then it should be fine
        return false;
      }
    }

    return null;
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
              backgroundColor: speakerOneBoxColor,
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
              duration: lengthOfColorSwapAnimation,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            // The second speaker's bubble
            ConversationSpeakerBubble(
              text: speakerTwoCurrentText,
              textColor: TranslifyColors.headerTextColor,
              backgroundColor: speakerTwoBoxColor,
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
              duration: lengthOfColorSwapAnimation,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .05),

            recording
                ? RecordingControls(
                    cancelButtonMessage: "Cancel Recording",
                    cancelButtonFunction: cancelRecording,
                    endButtonMessage: "Finish Recording",
                    endButtonFunction: endRecording,
                    buttonTextColor: TranslifyColors.headerTextColor,
                    buttonBackgroundColor: TranslifyColors.nonAdminButtonColor,
                  )
                : MicrophoneRow(
                    primarySpeakerColor:
                        TranslifyColors.convesationTranslationAccentColor,
                    primarySpeakerAction: () => {startRecording("primary")},
                    secondarySpeakerColor: TranslifyColors
                        .conversationTranslationSecondSpeakerColor,
                    secondarySpeakerAction: () => {startRecording("secondary")},
                    microphoneIconColor: TranslifyColors.darkButtonText,
                  ),
          ],
        ),
      ),
    );
  }
}
