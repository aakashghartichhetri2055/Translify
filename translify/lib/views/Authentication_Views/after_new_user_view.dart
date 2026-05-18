// Meant to be shown to the new user after they successfully sign up
// Asks the new user if they want to store their translations on our server so that they can look at them later

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/services/set_translation_history.dart';
import 'package:translify/services/get_history_setting.dart';

class AfterNewUserView extends StatefulWidget {
  const AfterNewUserView({super.key});

  @override
  State<AfterNewUserView> createState() => _AfterNewUserViewState();
}

class _AfterNewUserViewState extends State<AfterNewUserView> {
  bool switchState = false;

  Future<void> switchPressed(bool value) async {
    String setting = value ? "True" : "False";

    await setTranslationHistory(setting);

    setState(() {
      switchState = value;
    });
  }

  Future<void> loadSwitchState() async {
    String setting = await getHistorySetting();

    if (setting == "null" || setting == "False") {
      setState(() {
        switchState = false;
      });
    } else {
      setState(() {
        switchState = true;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    loadSwitchState();
  }

  void buttonPressed(BuildContext context) {
    // Try to send response back to server

    // Server response
    final response = true;

    if (response) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is kept here because switchState needs to be initialized first
    String switchMessage = switchState
        ? "Store my information"
        : "Don't store my information";

    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Cloud icon
          Center(
            child: Icon(
              Icons.cloud_queue,
              color: TranslifyColors.adminButtonColor,
              size: 150,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .01),

          // Big question for the user
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * .05,
                0,
                MediaQuery.of(context).size.width * .05,
                0,
              ),
              child: Text(
                "Allow Us To Store Your Translations?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TranslifyColors.headerTextColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Explanation of what saving their translations would enable
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * .1,
                0,
                MediaQuery.of(context).size.width * .1,
                0,
              ),
              child: Text(
                "Saving your translation will allow you to see them at any time",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TranslifyColors.headerTextColor,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Disclaimer
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * .1,
                0,
                MediaQuery.of(context).size.width * .1,
                0,
              ),
              child: Text(
                "We will never use your data for training, or sell your data to third parties",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TranslifyColors.headerTextColor,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // The switch row
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * .1,
              0,
              MediaQuery.of(context).size.width * .1,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  switchMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TranslifyColors.headerTextColor,
                    fontSize: 20,
                  ),
                ),

                Switch(
                  value: switchState,
                  onChanged: (value) => {switchPressed(value)},
                  inactiveTrackColor: TranslifyColors.textInputAccentColor,
                  inactiveThumbColor: TranslifyColors.adminButtonColor,
                  activeTrackColor: TranslifyColors.adminButtonColor,
                  activeThumbColor: TranslifyColors.textInputAccentColor,
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to confirm choice
          Button(
            action: () => {buttonPressed(context)},
            text: "Confirm",
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),
        ],
      ),
    );
  }
}
