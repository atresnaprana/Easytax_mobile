import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- Custom TextInputFormatter ---
class ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    String digitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    try {
      final number = int.parse(digitsOnly);
      final String formattedText = _formatter.format(number);
      return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } catch (e) {
      print("Error formatting number: $e");
      return oldValue;
    }
  }
}
