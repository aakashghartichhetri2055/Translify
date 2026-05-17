import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/services/log_out_service.dart';
import 'package:translify/services/get_user_history_service.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/widgets/history_card.dart';

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
    final history = await getUserHistoryService();

    setState(() {
      userHistory = history;
      historyLoaded = true;
    });
  }

  // Bool to check if history has loaded yet
  bool historyLoaded = false;

  // Variable that keeps the history
  late List<dynamic> userHistory;

  @override
  void initState() {
    super.initState();
    getUserHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,

      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Header for history
          Text(
            "Your Translation History:",
            style: TextStyle(
              color: TranslifyColors.headerTextColor,
              fontSize: 25,
            ),
          ),

          // The translation history items
          historyLoaded
              ? userHistory.isEmpty
                    ? Text(
                        "No History Saved",
                        style: TextStyle(
                          color: TranslifyColors.headerTextColor,
                          fontSize: 25,
                        ),
                      )
                    :
                      // Build the tiles of translation history
                      Expanded(
                        child: ListView.builder(
                          itemCount: userHistory.length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = userHistory[index];
                            return HistoryCard(
                              originalText: item["original_text"],
                              translatedText: item["translated_text"],
                              sourceLanguage: item["source_language"],
                              targetLangauge: item["target_language"],
                              mode: item["mode"] == "image"
                                  ? "Camera Translation"
                                  : "Conversation Translation",
                              backgroundColor:
                                  TranslifyColors.nonAdminButtonColor,
                              modeColor: item["mode"] == "image"
                                  ? TranslifyColors.cameraTranslationAccentColor
                                  : TranslifyColors
                                        .convesationTranslationAccentColor,
                              textTextColor: TranslifyColors.headerTextColor,
                              modeTextColor: TranslifyColors.darkButtonText,
                              adminButtonColor:
                                  TranslifyColors.adminButtonColor,
                            );
                          },
                        ),
                      )
              : CircularProgressIndicator(
                  color: TranslifyColors.adminButtonColor,
                ),

          // A button to log out
          Center(
            child: Button(
              text: "Log Out",
              action: () => logOutButtonPressed(context),
              backgroundColor: TranslifyColors.adminButtonColor,
              textColor: TranslifyColors.adminButtonTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
