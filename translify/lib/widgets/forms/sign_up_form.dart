import 'package:flutter/material.dart';
import 'package:translify/validation/validation.dart';
import 'package:translify/widgets/text_input.dart';

class SignUpForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final GlobalKey<FormState> formKey;

  const SignUpForm({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
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
              obscure: true,
            ),

            SizedBox(height: MediaQuery.of(context).size.height * .02),

            TextInput(
              controller: confirmPassword,
              hint: "Confirm your password",
              label: "Confirm Password",
              validator: Validators.confirmPassword(password),
              obscure: true,
            ),
          ],
        ),
      ),
    );
  }
}
