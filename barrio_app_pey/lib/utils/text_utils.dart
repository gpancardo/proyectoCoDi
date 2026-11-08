import 'package:flutter/material.dart';

abstract final class TextUtils {
  static String clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}

abstract final class FormUtils {
  static bool validateAndSave(FormState? form) => form?.validate() ?? false;
}
