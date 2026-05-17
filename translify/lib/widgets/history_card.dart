import 'package:flutter/material.dart';
import 'package:translify/languages/languages.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLangauge,
    required this.mode,
    required this.backgroundColor,
    required this.modeColor,
    required this.textTextColor,
    required this.modeTextColor,
    required this.adminButtonColor,
  });

  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLangauge;
  final String mode;

  final Color backgroundColor;
  final Color modeColor;
  final Color adminButtonColor;
  final Color modeTextColor;
  final Color textTextColor;
  final double textSize = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),

      margin: const EdgeInsets.symmetric(vertical: 12.0),

      width: MediaQuery.of(context).size.width * .9,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * .05,
          MediaQuery.of(context).size.height * .03,
          MediaQuery.of(context).size.width * .05,
          MediaQuery.of(context).size.height * .03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // The mode of the translation used
            Container(
              decoration: BoxDecoration(
                color: modeColor,
                borderRadius: BorderRadius.circular(20),
              ),

              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),

              child: Text(
                "Mode: $mode",
                style: TextStyle(color: modeTextColor, fontSize: textSize),
              ),
            ),

            SizedBox(height: 30),

            // The languages that were involed in the translation
            // The mode of the translation used
            Container(
              decoration: BoxDecoration(
                color: adminButtonColor,
                borderRadius: BorderRadius.circular(20),
              ),

              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),

              child: Text(
                "From ${Languages.values.firstWhere((lang) => lang.code == sourceLanguage).name} to ${Languages.values.firstWhere((lang) => lang.code == targetLangauge).name} ",
                style: TextStyle(color: modeTextColor, fontSize: textSize),
              ),
            ),

            SizedBox(height: 30),

            // The text of the original speech
            Text(
              "Original Text:",
              style: TextStyle(color: textTextColor, fontSize: textSize),
            ),

            SizedBox(height: 10),

            Text(
              originalText,
              style: TextStyle(color: textTextColor, fontSize: textSize),
            ),

            SizedBox(height: 30),

            // The translation of that text
            Text(
              "Translation:",
              style: TextStyle(color: textTextColor, fontSize: textSize),
            ),
            SizedBox(height: 10),

            Text(
              translatedText,
              style: TextStyle(color: textTextColor, fontSize: textSize),
            ),
          ],
        ),
      ),
    );
  }
}
