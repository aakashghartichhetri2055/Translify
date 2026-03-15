import 'package:flutter/material.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/forms/login_form.dart';
import 'package:translify/colors/colors.dart';

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
  void loginButtonTapped() {
    // Validate form content first
    if (!_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }

    // Send form content to backend

    // Receive response from server
    const response = true;

    // If response is good, save credentials and move user to next page (Homepage)
    // TODO: Add navigation here
    if (response) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cool!')));
    }

    // Else, inform user of bad response
  }

  // Function for when Sign Up button is clicked
  // TODO: Add navigation here
  void signUpButtonTapped() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cool!'), backgroundColor: Colors.red),
    );
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
            action: loginButtonTapped,
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),

          SizedBox(height: MediaQuery.of(context).size.height * .05),

          // Button to Take You to Sign Up Page
          Button(
            text: "Sign Up",
            action: signUpButtonTapped,
            backgroundColor: TranslifyColors.adminButtonColor,
            textColor: TranslifyColors.adminButtonTextColor,
          ),
        ],
      ),
    );
  }
}
