// Reusable Text Input widget

import 'package:flutter/material.dart';

/// Text Input Widget
/// Meant to be used within a Form Widget
/// Decoration for the Text Input is fixed
/// Parameters
///   TextEditingController controller: text controller for field
///   String hint: the hint shown when no text has been inputted
///   String label: the label for the text
///   bool obscure: whether to hide the text for the input; default false
///   String Function validator: the validator function for the text
class TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool obscure;
  final String? Function(String?)? validator;

  const TextInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    required this.validator,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .7,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white),

          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),

          // When the text field is unfocused
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),

          // When user is inputting text in the field
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),

          // Background color
          filled: true,
          fillColor: Color.fromRGBO(96, 92, 92, 1),
        ),

        // Validation, show error text below the input when the text is invalid
        // Useful for stuff like login
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
