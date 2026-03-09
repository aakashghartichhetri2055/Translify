import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

// Class to organize the validation functions for form input
// Currently have: email validation, password confirmation, and confirmPassword validation

class Validators {
  // Validation for email
  // Make sure that text is valid email
  static final email = FormBuilderValidators.compose([
    FormBuilderValidators.required(),
    FormBuilderValidators.email(),
  ]);

  // Validation for password
  // Right now, make sure that between 8 - 30 characters, has one lowercase, uppercase, and special symbol
  // From documentation, Special Characters are any characters that are not a Letter (a - z, A - Z) or Digit (0-9)
  static final password = FormBuilderValidators.compose([
    FormBuilderValidators.required(),
    FormBuilderValidators.password(
      minLength: 8,
      maxLength: 30,
      minLowercaseCount: 1,
      minUppercaseCount: 1,
      minSpecialCharCount: 1,
      checkNullOrEmpty: true,
    ),
  ]);

  // Validation for Confirm Password
  // Custom, since form_builder_validators does not really have an equivalent
  static String? Function(String?) confirmPassword(
    TextEditingController? password,
  ) {
    return (value) {
      // If the field is empty
      if (value == null || value.isEmpty) {
        return "Please confirm your password";
      }

      // If the password field is empty
      if (password == null || password.text.isEmpty) {
        return "Please enter a password first";
      }

      // If confirmPassword does not match with what is in password field
      if (value != password.text) {
        return "Passwords do not match";
      }

      // Validation passes, return null for validator
      return null;
    };
  }
}
