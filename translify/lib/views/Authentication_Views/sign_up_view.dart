import 'package:flutter/material.dart';
import 'package:translify/widgets/button.dart';
import 'package:translify/widgets/forms/sign_up_form.dart';

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
  void signUpButtonTapped() {
    // Validate form content first
    if (!_signUpFormKey.currentState!.validate()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(15, 15, 15, 1),
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
          Button(text: "Sign Up!", action: signUpButtonTapped),
        ],
      ),
    );
  }
}
