import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:translify/router/routes.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/forms/sign_up_form.dart';
import 'package:translify/colors/colors.dart';
import 'package:translify/services/sign_up_service.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  // Text controllers for Sign Up Form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Global Key for Form
  final _signUpFormKey = GlobalKey<FormState>();

  // Dispose of the text controllers when changing views
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // For when the Sign Up Button is clicked
  void signUpButtonTapped(BuildContext context) async {
    // Validate form content first
    if (!_signUpFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      return;
    }

    // Send form content to backend
    try {
      String? response = await signUpService(
        _emailController.text,
        _passwordController.text,
      );

      if (response == "Good") {
        BuildContext contextCheck = context;
        if (!contextCheck.mounted) return;

        // Send the user back to the login page
        context.pop;
      }
    } catch (error) {
      print(error);
    }
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
            style: TextStyle(color: Colors.white, fontSize: 50),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .1),

          // Sign Up Form
          SignUpForm(
            email: _emailController,
            password: _passwordController,
            confirmPassword: _confirmPasswordController,
            formKey: _signUpFormKey,
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to confirm the signup
          Button(
            text: "Sign Up!",
            action: () => {signUpButtonTapped(context)},
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),
        ],
      ),
    );
  }
}
