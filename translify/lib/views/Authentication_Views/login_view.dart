import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/forms/login_form.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/services/login_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Text controllers for Login Form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Global Key for Form
  final _loginFormKey = GlobalKey<FormState>();

  // Dispose of the text controllers when changing views
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function for when Login button is clicked
  void loginButtonTapped(BuildContext context) async {
    // Validate form content first
    if (!_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      return;
    }

    // Send form content to backend
    try {
      bool? response = await loginService(
        _emailController.text,
        _passwordController.text,
      );

      if (response) {
        BuildContext contextCheck = context;
        if (!contextCheck.mounted) return;

        context.go(AppRoutes.afterNewUser);
      }
    } catch (error) {
      print(error);
    }
  }

  // Function for when Sign Up button is clicked
  void signUpButtonTapped(BuildContext context) {
    context.push(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TranslifyColors.backgroundColor,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Text Logo
          Text(
            "Translify",
            style: TextStyle(
              color: TranslifyColors.headerTextColor,
              fontSize: 50,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Login Form
          LoginForm(
            email: _emailController,
            password: _passwordController,
            formKey: _loginFormKey,
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to confirm the signup
          Button(
            text: "Log In!",
            action: () => {loginButtonTapped(context)},
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to Take You to Sign Up Page
          Button(
            text: "Sign Up",
            action: () => {signUpButtonTapped(context)},
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),
        ],
      ),
    );
  }
}
