import 'package:flutter/material.dart';
import 'package:translify/widgets/text_input.dart';
import 'package:translify/validation/validation.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final GlobalKey<FormState> formKey;

  const LoginForm({
    super.key,
    required this.email,
    required this.password,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Center(
        child: Column(
          children: [
            TextInput(
              controller: email,
              hint: "Email",
              label: "Email",
              validator: Validators.email,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .02),

            TextInput(
              controller: password,
              hint: "Password",
              label: "Password",
              validator: Validators.password,
            ),
          ],
        ),
      ),
    );
  }
}

/// TO DO: add text input fields + validator functions here
