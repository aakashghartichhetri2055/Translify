import 'package:flutter/material.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/services/get_user_status.dart';
import 'package:translify/router/routes.dart';
import 'package:go_router/go_router.dart';

class AuthCheckView extends StatefulWidget {
  const AuthCheckView({super.key});

  @override
  State<AuthCheckView> createState() => _AuthCheckViewState();
}

class _AuthCheckViewState extends State<AuthCheckView> {
  // Function to check the user's authentication status, and to direct them to the correct views
  Future<void> checkAuthStatus() async {
    // Get an instance of go router to use
    // Have to do this because this function is called in init state, before any context is actually formed
    final router = GoRouter.of(context);

    bool authGood = await getUserStatus();

    if (!mounted) return;

    // Go to view based on status
    if (authGood) {
      router.go(AppRoutes.home);
    } else {
      router.go(AppRoutes.login);
    }
  }

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: TranslifyColors.adminButtonColor,
        ),
      ),
    );
  }
}
