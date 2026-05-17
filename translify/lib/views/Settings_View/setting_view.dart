import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/services/log_out_service.dart';
import 'package:translify/router/routes.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  // Log out function
  Future<void> logOutButtonPressed(BuildContext context) async {
    await logOutService();

    BuildContext contextCheck = context;

    if (!contextCheck.mounted) {
      return;
    } else {
      context.go(AppRoutes.login);
    }
  }

  // Function to get translation history
  Future<dynamic> getUserHistory() async {
    var history = await getUserHistoryService();
  }

  // Bool to check if history has loaded yet
  bool historyLoaded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: ListView(
        children: [
          // A button to log out
          Button(
            text: "Log Out",
            action: () => logOutButtonPressed(context),
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),

          // Header for history
          Text(
            "Your Translation History:",
            style: TextStyle(
              color: TranslifyColors.headerTextColor,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
