import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io'; // Keep for File, Platform, FileSystemException
import 'dart:typed_data'; // Keep for Uint8List
import 'package:path_provider/path_provider.dart'; // Keep for getApplicationDocumentsDirectory
import 'package:permission_handler/permission_handler.dart'; // Keep for Permission
import 'package:dropdown_search/dropdown_search.dart'; // Keep if used for Add page
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

// --- Define your Base URL ---
const String baseUrl = 'http://192.168.100.176:13080'; // ADJUST AS NEEDED

// --- Data Model Class for Memorial Journal Entry ---
// --- ORIGINAL Data Model Class for Memorial Journal LIST VIEW ---
// --- Data Model Class for Memorial Journal Entry (UPDATED) ---
class MemorialJournalEntry {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final double debit;
  final double credit;
  final String debitStr; // Keep as is for existing list view
  final String creditStr; // Keep as is for existing list view
  final String transDateStr;

  // --- NEW FIELDS ---
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  // Store API date strings, parse for display
  final String? entryDate; // e.g., "2025-01-12T21:46:14"
  final String? updateDate; // e.g., "2025-01-12T21:46:14"
  // ------------------

  MemorialJournalEntry({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunCredit,
    required this.debit,
    required this.credit,
    required this.debitStr,
    required this.creditStr,
    required this.transDateStr,
    // --- Add to constructor ---
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
    // ------------------------
  });

  factory MemorialJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value
            .replaceAll(RegExp(r'[.]'), '')
            .replaceAll(',', '.');
        return double.tryParse(cleanedValue) ?? 0.0;
      }
      return 0.0;
    }

    return MemorialJournalEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      debit: parseDouble(json['debit']),
      credit: parseDouble(json['credit']),
      // Use keys from your list API if they differ, but from your sample they seem to be null here
      debitStr:
          json['debitStr'] ??
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: '',
            decimalDigits: 2,
          ).format(parseDouble(json['debit'])),
      creditStr:
          json['creditStr'] ??
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: '',
            decimalDigits: 2,
          ).format(parseDouble(json['credit'])),
      transDateStr:
          json['transDateStr'] ??
          '', // Or DateFormat('dd MMM yyyy').format(DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970))
      // --- Map NEW FIELDS from JSON ---
      entryUser: json['entry_user'], // Directly from JSON
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate:
          json['entry_date'], // API sends as String "2025-01-12T21:46:14"
      updateDate:
          json['update_date'], // API sends as String "2025-01-12T21:46:14"
      // ------------------------------
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedDebit => debitStr;
  String get formattedCredit => creditStr;
}

class PurchaseJournalEntry {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int
  akunDebitdisc; // Note: These might not be used in current display/sort
  final int
  akunCreditdisc; // Note: These might not be used in current display/sort
  final double Value; // Numeric value for sorting/calculations
  final double ValueDisc; // Numeric value for discount sorting/calculations
  final String ValueStr; // Formatted string for display
  final String ValueStrdisc; // Formatted string for display
  final String transDateStr;

  // --- NEW FIELDS ---
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;
  // ------------------

  PurchaseJournalEntry({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunDebitdisc,
    required this.akunCredit,
    required this.akunCreditdisc,
    required this.Value,
    required this.ValueDisc,
    required this.ValueStr,
    required this.ValueStrdisc,
    required this.transDateStr,
    // --- Add to constructor ---
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
    // ------------------------
  });

  factory PurchaseJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value
            .replaceAll(RegExp(r'[.]'), '')
            .replaceAll(',', '.');
        return double.tryParse(cleanedValue) ?? 0.0;
      }
      return 0.0;
    }

    // Make sure keys match your API response exactly
    return PurchaseJournalEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunDebitdisc: json['akun_Debitdisc'] ?? 0, // Check API key
      akunCredit: json['akun_Credit'] ?? 0,
      akunCreditdisc: json['akun_Creditdisc'] ?? 0, // Check API key
      Value: parseDouble(json['value']), // Check API key ('value' or 'Value'?)
      ValueDisc: parseDouble(
        json['value_Disc'],
      ), // Check API key ('value_Disc' or 'ValueDisc'?)
      ValueStr: json['valueStr'] ?? '0,00', // Check API key
      ValueStrdisc:
          json['valueDiscStr'] ?? '0,00', // Check API key ('valueDiscStr'?)
      transDateStr: json['transDateStr'] ?? '',
      // --- Map NEW FIELDS from JSON ---
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
      // ------------------------------
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => ValueStr; // Use ValueStr for display
  String get formattedValueDisc => ValueStrdisc; // Use ValueStrdisc for display
}

class SalesJournalEntry {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int
  akunDebitdisc; // Note: These might not be used in current display/sort
  final int
  akunCreditdisc; // Note: These might not be used in current display/sort
  final double Value; // Numeric value for sorting/calculations
  final double ValueDisc; // Numeric value for discount sorting/calculations
  final String ValueStr; // Formatted string for display
  final String ValueStrdisc; // Formatted string for display
  final String transDateStr;
  // --- NEW FIELDS ---
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;
  // ------------------
  SalesJournalEntry({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunDebitdisc,
    required this.akunCredit,
    required this.akunCreditdisc,
    required this.Value,
    required this.ValueDisc,
    required this.ValueStr,
    required this.ValueStrdisc,
    required this.transDateStr,
    // --- Add to constructor ---
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
    // ------------------------
  });

  factory SalesJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value
            .replaceAll(RegExp(r'[.]'), '')
            .replaceAll(',', '.');
        return double.tryParse(cleanedValue) ?? 0.0;
      }
      return 0.0;
    }

    // Make sure keys match your API response exactly
    return SalesJournalEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunDebitdisc: json['akun_Debitdisc'] ?? 0, // Check API key
      akunCredit: json['akun_Credit'] ?? 0,
      akunCreditdisc: json['akun_Creditdisc'] ?? 0, // Check API key
      Value: parseDouble(json['value']), // Check API key ('value' or 'Value'?)
      ValueDisc: parseDouble(
        json['value_Disc'],
      ), // Check API key ('value_Disc' or 'ValueDisc'?)
      ValueStr: json['valueStr'] ?? '0,00', // Check API key
      ValueStrdisc:
          json['valueDiscStr'] ?? '0,00', // Check API key ('valueDiscStr'?)
      transDateStr: json['transDateStr'] ?? '',
      // --- Map NEW FIELDS from JSON ---
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
      // ------------------------------
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => ValueStr; // Use ValueStr for display
  String get formattedValueDisc => ValueStrdisc; // Use ValueStrdisc for display
}

// --- Account Model ---
class Account {
  final int accountNo;
  final String accountName;

  Account({required this.accountNo, required this.accountName});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountNo: json['account_no'] ?? 0,
      accountName: json['account_name'] ?? 'Unknown Account',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          accountNo == other.accountNo;

  @override
  int get hashCode => accountNo.hashCode;

  @override
  String toString() {
    return 'Account{accountNo: $accountNo, accountName: $accountName}';
  }
}

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

// --- NEW Data Model Class for Memorial Journal DETAIL VIEW ---
class MemorialJournalDetail {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit; // Account Number for Debit
  final int akunCredit; // Account Number for Credit
  final double debit; // Numeric value for Debit
  final double credit; // Numeric value for Credit
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final DateTime? updateDate;
  final DateTime? entryDate;
  // final List<Account>? dddbacc; // This was null in your sample, handle if it can be present
  // final String? debitStr;      // This was null in your sample
  // final String? creditStr;     // This was null in your sample

  // For displaying account names after fetching them separately
  String debitAccountName;
  String creditAccountName;

  MemorialJournalDetail({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunCredit,
    required this.debit,
    required this.credit,
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.updateDate,
    this.entryDate,
    // this.dddbacc,
    // this.debitStr,
    // this.creditStr,
    this.debitAccountName = '', // Initialize
    this.creditAccountName = '', // Initialize
  });

  factory MemorialJournalDetail.fromJson(Map<String, dynamic> json) {
    // Helper to parse numeric fields that might come as int or double
    double parseNumeric(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      // Should not expect string for numeric values in this specific API response
      return 0.0;
    }

    return MemorialJournalDetail(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      debit: parseNumeric(json['debit']), // API returns numbers for detail
      credit: parseNumeric(json['credit']), // API returns numbers for detail
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      updateDate: DateTime.tryParse(json['update_date'] ?? ''),
      entryDate: DateTime.tryParse(json['entry_date'] ?? ''),
      // dddbacc: (json['dddbacc'] as List?)?.map((accJson) => Account.fromJson(accJson)).toList(),
      // debitStr: json['debitStr'], // These are null in your sample
      // creditStr: json['creditStr'],
    );
  }

  // Formatted date
  String get formattedDateDisplay =>
      DateFormat('dd MMM yyyy').format(transDate);

  // Formatter for numeric debit/credit values
  String get formattedDebitValue {
    final formatter = NumberFormat.decimalPattern('id'); // For "100.000.000"
    return formatter.format(debit);
  }

  String get formattedCreditValue {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(credit);
  }

  String get formattedEntryDate =>
      entryDate != null
          ? DateFormat('dd MMM yyyy, HH:mm').format(entryDate!)
          : 'N/A';
  String get formattedUpdateDate =>
      updateDate != null
          ? DateFormat('dd MMM yyyy, HH:mm').format(updateDate!)
          : 'N/A';
}

// --- Data Model for Account Settings List/Grid View ---
class AccountSettingEntry {
  final int id;
  final String? companyId;
  final int accountNo;
  final String? hierarchy;
  final String accountName;
  final String? akunDK; // Debit/Kredit normal balance
  final String? akunNRLR; // Neraca/LabaRugi (Balance Sheet/Income Statement)
  final String? accountType; // Could be more specific if values are known
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif; // '1' for active, '0' for inactive
  final DateTime? updateDate;
  final DateTime? entryDate;

  AccountSettingEntry({
    required this.id,
    this.companyId,
    required this.accountNo,
    this.hierarchy,
    required this.accountName,
    this.akunDK,
    this.akunNRLR,
    this.accountType,
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.updateDate,
    this.entryDate,
  });

  factory AccountSettingEntry.fromJson(Map<String, dynamic> json) {
    return AccountSettingEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'],
      accountNo: json['account_no'] ?? 0,
      hierarchy: json['hierarchy'],
      accountName: json['account_name'] ?? 'Unknown Account',
      akunDK: json['akundk'],
      akunNRLR: json['akunnrlr'],
      accountType: json['account_Type'], // Key from JSON
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      updateDate:
          json['update_date'] != null
              ? DateTime.tryParse(json['update_date'])
              : null,
      entryDate:
          json['entry_date'] != null
              ? DateTime.tryParse(json['entry_date'])
              : null,
    );
  }

  String get formattedUpdateDate =>
      updateDate != null
          ? DateFormat('dd MMM yyyy').format(updateDate!)
          : 'N/A';
  String get formattedEntryDate =>
      entryDate != null ? DateFormat('dd MMM yyyy').format(entryDate!) : 'N/A';
  String get status =>
      flagAktif == '1' ? 'Active' : (flagAktif == '0' ? 'Inactive' : 'N/A');
}

// --- Data Model for DETAILED Purchase Journal Entry View ---
class PurchaseJournalDetail {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int akunDebitDisc; // Using your specified key: akun_Debit_disc
  final int akunCreditDisc; // Using your specified key: akun_Credit_disc
  final double value; // Using your specified key: value
  final double valueDisc; // Using your specified key: value_Disc

  // Detail fields
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate; // API sends as String
  final String? updateDate; // API sends as String

  // Formatted string getters (will be populated by fromJson if API returns null for string versions)
  final String valueStr;
  final String valueDiscStr;

  PurchaseJournalDetail({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunCredit,
    required this.akunDebitDisc,
    required this.akunCreditDisc,
    required this.value,
    required this.valueDisc,
    required this.valueStr,
    required this.valueDiscStr,
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
  });

  factory PurchaseJournalDetail.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[.]'), '').replaceAll(',', '.');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    String formatAmount(double amount) {
      return NumberFormat("#,##0.00", "id_ID").format(amount);
    }

    return PurchaseJournalDetail(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate:
          DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970, 1, 1),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      akunDebitDisc: json['akun_Debit_disc'] ?? 0, // Key from your sample
      akunCreditDisc: json['akun_Credit_disc'] ?? 0, // Key from your sample
      value: parseDouble(json['value']), // Key from your sample
      valueDisc: parseDouble(json['value_Disc']), // Key from your sample

      valueStr: json['valueStr'] ?? formatAmount(parseDouble(json['value'])),
      valueDiscStr:
          json['valueDiscStr'] ?? formatAmount(parseDouble(json['value_Disc'])),

      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => valueStr;
  String get formattedValueDisc => valueDiscStr;
}

// --- Data Model for DETAILED Sales Journal Entry View ---
// This will be identical to PurchaseJournalDetail if both detail APIs return the same structure
// with 'value' and 'value_Disc'. If Sales detail API uses 'debit'/'credit', this needs adjustment.
// For now, assuming it's the same as Purchase Detail based on your request.
class SalesJournalDetail {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int akunDebitDisc;
  final int akunCreditDisc;
  final double
  value; // For Sales, 'value' might represent Total Sales Revenue (Credit side typically)
  final double
  valueDisc; // For Sales, 'valueDisc' might represent Sales Discount (Debit side typically)

  // Detail fields
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

  final String valueStr;
  final String valueDiscStr;

  SalesJournalDetail({
    required this.id,
    required this.companyId,
    required this.transDate,
    required this.transNo,
    required this.description,
    required this.akunDebit,
    required this.akunCredit,
    required this.akunDebitDisc,
    required this.akunCreditDisc,
    required this.value,
    required this.valueDisc,
    required this.valueStr,
    required this.valueDiscStr,
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
  });

  factory SalesJournalDetail.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      /* ... same helper ... */
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[.]'), '').replaceAll(',', '.');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    String formatAmount(double amount) {
      /* ... same helper ... */
      return NumberFormat("#,##0.00", "id_ID").format(amount);
    }

    return SalesJournalDetail(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate:
          DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970, 1, 1),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      akunDebitDisc: json['akun_Debit_disc'] ?? 0,
      akunCreditDisc: json['akun_Credit_disc'] ?? 0,
      value: parseDouble(
        json['value'],
      ), // Assuming Sales Detail API uses 'value'
      valueDisc: parseDouble(
        json['value_Disc'],
      ), // Assuming Sales Detail API uses 'value_Disc'

      valueStr: json['valueStr'] ?? formatAmount(parseDouble(json['value'])),
      valueDiscStr:
          json['valueDiscStr'] ?? formatAmount(parseDouble(json['value_Disc'])),

      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => valueStr;
  String get formattedValueDisc => valueDiscStr;
}

// --- Main Application Entry Point ---
void main() {
  runApp(MyApp());
}

// --- Root Widget ---
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyTax Mobile',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Splash Screen ---
// --- Splash Screen (with Custom Logo) ---
class SplashScreen extends StatelessWidget {
  Future<bool> _checkLoginStatus() async {
    // Keep the delay or adjust as needed
    await Future.delayed(
      Duration(seconds: 2),
    ); // Increased delay slightly for logo visibility
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        // Show logo and optional indicator while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            // Optional: Set a background color matching your app theme or logo background
            backgroundColor: Colors.white, // Example: white background
            body: Center(
              child: Column(
                // Use Column to stack logo and indicator
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // --- Your Logo ---
                  Image.asset(
                    'assets/easytaxlandscape.png', // <-- *** REPLACE WITH YOUR LOGO PATH ***
                    height: 150, // Adjust size as needed
                    // width: 150, // You can also set width
                  ),
                  SizedBox(height: 24), // Spacing between logo and indicator
                  // --- Optional Loading Indicator ---
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ), // Match your theme
                  ),
                ],
              ),
            ),
          );
        }
        // Once future completes, navigate based on login status
        else {
          if (snapshot.hasError) {
            print("Error checking login: ${snapshot.error}");
            // Consider showing an error message briefly before navigating
            return LoginPage(); // Default to login on error
          }
          if (snapshot.data == true) {
            // Navigate to Dashboard
            // Using WidgetsBinding ensures navigation happens after build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            });
          } else {
            // Navigate to Login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            });
          }
          // Return a temporary placeholder while navigation is scheduled
          // This prevents a brief flash of the splash content after the future completes
          // but before navigation occurs.
          return Scaffold(
            backgroundColor: Colors.white, // Match the splash background
            body: Center(
              child: CircularProgressIndicator(),
            ), // Or just an empty container
          );
        }
      },
    );
  }
}

// --- Login Page ---
// --- Login Page (with Logo) ---
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    // ... (login logic remains the same) ...
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = "Username and Password cannot be empty.";
        _isLoading = false;
      });
      return;
    }
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('$baseUrl/api/Auth/login'));
    request.body = json.encode({"username": username, "password": password});
    request.headers.addAll(headers);
    try {
      http.StreamedResponse responseStream = await request.send().timeout(
        Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(responseStream);
      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String? token = data['token'];
        if (token != null && token.isNotEmpty) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('userid', username);
          await prefs.setBool('loggedIn', true);
          print("Login successful. Token saved: $token");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
          return;
        } else {
          _error = "Login successful, but no token received.";
        }
      } else {
        String serverMessage = response.reasonPhrase ?? 'Unknown Error';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ?? errorData['error'] ?? serverMessage;
        } catch (_) {
          /* Ignore */
        }
        _error = "Login failed: ${response.statusCode} - $serverMessage";
        print("Login failed: ${response.statusCode} ${response.reasonPhrase}");
        print("Response body: ${response.body}");
      }
    } on TimeoutException {
      _error = "Login request timed out. Please try again.";
    } on http.ClientException catch (e) {
      _error = "Network error: ${e.message}. Please check connection.";
    } catch (e) {
      _error = "An unexpected error occurred: ${e.toString()}";
      print("Login error: $e");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional: Remove AppBar if the logo makes it redundant
      // appBar: AppBar(title: Text('Login')),
      body: SafeArea(
        // Use SafeArea to avoid notch/system intrusions
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- ADD YOUR LOGO HERE ---
                Image.asset(
                  'assets/easytaxlandscape.png', // <-- *** REPLACE WITH YOUR LOGO PATH ***
                  height: 300, // Adjust size as needed for login screen
                  // width: 150,
                ),
                SizedBox(height: 24), // Spacing after logo
                // --- Error Message ---
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // --- Username Field ---
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // --- Password Field ---
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                SizedBox(height: 24),

                // --- Login Button / Loading Indicator ---
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        textStyle: TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Dashboard Page ---
// --- Dashboard Page (with App Logo instead of User Avatar) ---
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userIdentifier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userIdentifier = prefs.getString('userid') ?? 'N/A';
      _isLoading = false;
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userid');
    await prefs.setBool('loggedIn', false);
    if (!mounted) return;
    // Use context available in the State class directly
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigate(Widget page) {
    // Use context available in the State class directly
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildTile(IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () => _navigate(page),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  SizedBox(height: 30), // Adjusted top spacing
                  // --- REPLACE CircleAvatar with App Logo ---
                  Image.asset(
                    'assets/easytaxlandscape.png', // <-- *** REPLACE WITH YOUR LOGO PATH ***
                    height: 110, // Adjust size as needed for dashboard
                    // width: 150, // Optional: Set width if needed
                  ),

                  // -----------------------------------------
                  SizedBox(height: 15), // Adjusted spacing after logo
                  // --- Keep User Identifier Text ---
                  Text(
                    _userIdentifier ?? 'User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 25), // Adjusted spacing before grid
                  // --- Grid View remains the same ---
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: EdgeInsets.all(16),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildTile(
                          Icons.book_outlined,
                          'Memorial Journal',
                          MemorialJournalPage(),
                        ),
                        _buildTile(
                          Icons.receipt_long_outlined,
                          'Sales Journal',
                          SalesJournalPage(),
                        ),
                        _buildTile(
                          Icons.shopping_cart_outlined,
                          'Purchasing Journal',
                          PurchasingJournalPage(),
                        ),
                        _buildTile(
                          Icons.download_for_offline_outlined,
                          'Download Report',
                          DownloadReportPage(),
                        ),
                        _buildTile(
                          Icons.admin_panel_settings_outlined,
                          'Admin Menu',
                          AdminMenuPage(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

// ================================================================
// ADD MEMORIAL JOURNAL ENTRY PAGE
// ================================================================
class AddSalesJournalEntryPage extends StatefulWidget {
  // Added StatefulWidget definition
  @override
  _AddSalesJournalEntryPageState createState() =>
      _AddSalesJournalEntryPageState();
}

class _AddSalesJournalEntryPageState extends State<AddSalesJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _valueDiscController =
      TextEditingController(); // Controller for Discount Value

  DateTime? _selectedDate;
  List<Account> _accountsList = [];
  Account? _selectedDebitAccount;
  Account? _selectedCreditAccount;
  Account? _selectedDebitAccountDisc; // State for Debit Discount Account
  Account? _selectedCreditAccountDisc; // State for Credit Discount Account

  bool _isLoadingAccounts = true;
  String? _accountError;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _valueDiscController.dispose(); // Dispose discount controller
    super.dispose();
  }

  // --- Fetch Accounts (No changes needed here) ---
  Future<void> _fetchAccounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
      _accountError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }
      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _accountsList =
              data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
          _isLoadingAccounts = false;
        });
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      _accountError = "Fetching accounts timed out.";
    } on http.ClientException catch (e) {
      _accountError = "Network error fetching accounts: ${e.message}.";
    } catch (e) {
      print("Error fetching accounts: $e");
      _accountError = "An error occurred fetching accounts: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  // --- Select Date (No changes needed here) ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Submit Journal Entry (CORRECTED Validation & Parsing) ---
  Future<void> _submitJournalEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Basic validation
    if (_selectedDate == null ||
        _selectedDebitAccount == null ||
        _selectedCreditAccount == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill Date, Debit Account, and Credit Account.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
    // Check if main accounts are the same
    if (_selectedDebitAccount!.accountNo == _selectedCreditAccount!.accountNo) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Main Debit and Credit accounts cannot be the same.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    // --- ADDED: Validation for Discount Accounts (if selected) ---
    // Modify this logic if discount accounts are *required* even if discount amount is 0
    bool hasDiscountAmount =
        _valueDiscController.text.replaceAll('.', '').isNotEmpty &&
        double.tryParse(_valueDiscController.text.replaceAll('.', '')) != 0;
    if (hasDiscountAmount) {
      if (_selectedDebitAccountDisc == null ||
          _selectedCreditAccountDisc == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select both Debit and Credit Discount accounts if entering a discount value.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        return;
      }
      if (_selectedDebitAccountDisc!.accountNo ==
          _selectedCreditAccountDisc!.accountNo) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Discount Debit and Credit accounts cannot be the same.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        return;
      }
      // Optional: Check if discount accounts conflict with main accounts
      // if (_selectedDebitAccountDisc!.accountNo == _selectedDebitAccount!.accountNo || ... etc) { ... }
    }
    // ----------------------------------------------------------

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }

      final String formattedDate = DateFormat(
        "yyyy-MM-dd",
      ).format(_selectedDate!);
      final String description = _descriptionController.text;
      final int debitAccountNo = _selectedDebitAccount!.accountNo;
      final int creditAccountNo = _selectedCreditAccount!.accountNo;

      // --- CORRECTED: Use correct controller for discount value ---
      final String valueString = _valueController.text.replaceAll('.', '');
      final String valueDiscString = _valueDiscController.text.replaceAll(
        '.',
        '',
      ); // Use discount controller
      // --------------------------------------------------------

      final double? amount = double.tryParse(valueString);
      // Parse discount, default to 0.0 if empty or invalid
      final double amountdisc = double.tryParse(valueDiscString) ?? 0.0;

      if (amount == null || amount <= 0) {
        // Keep validation for the main value
        throw Exception('Invalid or zero amount entered for Value.');
      }

      // Convert to int for the body
      final int amountInt = amount.toInt();
      final int amountdiscInt = amountdisc.toInt();

      // Handle null discount accounts if amount is zero (send 0 or null based on API needs)
      // Sending 0 if not selected and amount is 0 might be safer if API expects the fields
      final int debitAccountNoDisc =
          (amountdiscInt != 0 && _selectedDebitAccountDisc != null)
              ? _selectedDebitAccountDisc!.accountNo
              : 0; // Or handle null if API allows
      final int creditAccountNoDisc =
          (amountdiscInt != 0 && _selectedCreditAccountDisc != null)
              ? _selectedCreditAccountDisc!.accountNo
              : 0; // Or handle null if API allows

      // Prepare body, ensure keys match API ('Value_Disc', 'Akun_Debit_disc' etc.)
      final body = json.encode({
        "TransDate": formattedDate,
        "Description": description,
        "Akun_Debit": debitAccountNo,
        "Akun_Credit": creditAccountNo,
        // Use names consistent with your API expectation
        "Akun_Debit_disc": debitAccountNoDisc,
        "Akun_Credit_disc": creditAccountNoDisc,
        "Value": amountInt,
        "Value_Disc": amountdiscInt,
      });

      final url = Uri.parse('$baseUrl/api/API/SubmitJPN');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("Submitting JPB: $body");

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Submit Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase Journal entry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String serverMessage = response.reasonPhrase ?? 'Submission Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Submit Failed Body: ${response.body}");
        throw Exception(
          'Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _submitError = "Submission request timed out.";
    } on http.ClientException catch (e) {
      _submitError = "Network error during submission: ${e.message}.";
    } catch (e) {
      print("Error submitting purchase journal entry: $e");
      _submitError = "An error occurred during submission: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Purchase Journal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Date Selection (No changes) ---
              Text(
                'Transaction Date:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // --- Description Input (No changes) ---
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter transaction description',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Accounts Loading/Error State ---
              if (_isLoadingAccounts)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_accountError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Error loading accounts: $_accountError',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                // --- Debit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccount,
                  itemAsString:
                      (Account acc) => acc.accountName, // Display name
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Account",
                      hintText: "Select Debit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true, // Keep search box enabled
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ), // Simplified hint
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedDebitAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a debit account.'
                              : null,
                ),
                SizedBox(height: 16),

                // --- Credit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccount,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Account",
                      hintText: "Select Credit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedCreditAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a credit account.'
                              : null,
                ),
                SizedBox(height: 16),

                // --- Discount Debit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Disc Account (Optional)",
                      hintText: "Select Debit Disc Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedDebitAccountDisc = newValue;
                    });
                  },
                  // No validator - optional field
                ),
                SizedBox(height: 16),

                // --- Discount Credit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Disc Account (Optional)",
                      hintText: "Select Credit Disc Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedCreditAccountDisc = newValue;
                    });
                  },
                  // No validator - optional field
                ),
                SizedBox(height: 16),
              ],

              // --- Value Input (No changes) ---
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount for Value.';
                  }
                  final cleanedValue = value.replaceAll('.', '');
                  final number = double.tryParse(cleanedValue);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid positive amount for Value.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Discount Value Input (No changes) ---
              TextFormField(
                controller: _valueDiscController,
                decoration: InputDecoration(
                  labelText: 'Value Disc (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter discount amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
              ),
              SizedBox(height: 24),

              // --- Submission Error / Button (No changes) ---
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child:
                    _isSubmitting
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text('Submit Entry'),
                          onPressed: _submitJournalEntry,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ADD PURCHASE JOURNAL ENTRY PAGE (Corrected)
// ================================================================
class AddPurchaseJournalEntryPage extends StatefulWidget {
  // Added StatefulWidget definition
  @override
  _AddPurchaseJournalEntryPageState createState() =>
      _AddPurchaseJournalEntryPageState();
}

class _AddPurchaseJournalEntryPageState
    extends State<AddPurchaseJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _valueDiscController =
      TextEditingController(); // Controller for Discount Value

  DateTime? _selectedDate;
  List<Account> _accountsList = [];
  Account? _selectedDebitAccount;
  Account? _selectedCreditAccount;
  Account? _selectedDebitAccountDisc; // State for Debit Discount Account
  Account? _selectedCreditAccountDisc; // State for Credit Discount Account

  bool _isLoadingAccounts = true;
  String? _accountError;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _valueDiscController.dispose(); // Dispose discount controller
    super.dispose();
  }

  // --- Fetch Accounts (No changes needed here) ---
  Future<void> _fetchAccounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
      _accountError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }
      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _accountsList =
              data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
          _isLoadingAccounts = false;
        });
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      _accountError = "Fetching accounts timed out.";
    } on http.ClientException catch (e) {
      _accountError = "Network error fetching accounts: ${e.message}.";
    } catch (e) {
      print("Error fetching accounts: $e");
      _accountError = "An error occurred fetching accounts: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  // --- Select Date (No changes needed here) ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Submit Journal Entry (CORRECTED Validation & Parsing) ---
  Future<void> _submitJournalEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Basic validation
    if (_selectedDate == null ||
        _selectedDebitAccount == null ||
        _selectedCreditAccount == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill Date, Debit Account, and Credit Account.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
    // Check if main accounts are the same
    if (_selectedDebitAccount!.accountNo == _selectedCreditAccount!.accountNo) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Main Debit and Credit accounts cannot be the same.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    // --- ADDED: Validation for Discount Accounts (if selected) ---
    // Modify this logic if discount accounts are *required* even if discount amount is 0
    bool hasDiscountAmount =
        _valueDiscController.text.replaceAll('.', '').isNotEmpty &&
        double.tryParse(_valueDiscController.text.replaceAll('.', '')) != 0;
    if (hasDiscountAmount) {
      if (_selectedDebitAccountDisc == null ||
          _selectedCreditAccountDisc == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select both Debit and Credit Discount accounts if entering a discount value.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        return;
      }
      if (_selectedDebitAccountDisc!.accountNo ==
          _selectedCreditAccountDisc!.accountNo) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Discount Debit and Credit accounts cannot be the same.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        return;
      }
      // Optional: Check if discount accounts conflict with main accounts
      // if (_selectedDebitAccountDisc!.accountNo == _selectedDebitAccount!.accountNo || ... etc) { ... }
    }
    // ----------------------------------------------------------

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }

      final String formattedDate = DateFormat(
        "yyyy-MM-dd",
      ).format(_selectedDate!);
      final String description = _descriptionController.text;
      final int debitAccountNo = _selectedDebitAccount!.accountNo;
      final int creditAccountNo = _selectedCreditAccount!.accountNo;

      // --- CORRECTED: Use correct controller for discount value ---
      final String valueString = _valueController.text.replaceAll('.', '');
      final String valueDiscString = _valueDiscController.text.replaceAll(
        '.',
        '',
      ); // Use discount controller
      // --------------------------------------------------------

      final double? amount = double.tryParse(valueString);
      // Parse discount, default to 0.0 if empty or invalid
      final double amountdisc = double.tryParse(valueDiscString) ?? 0.0;

      if (amount == null || amount <= 0) {
        // Keep validation for the main value
        throw Exception('Invalid or zero amount entered for Value.');
      }

      // Convert to int for the body
      final int amountInt = amount.toInt();
      final int amountdiscInt = amountdisc.toInt();

      // Handle null discount accounts if amount is zero (send 0 or null based on API needs)
      // Sending 0 if not selected and amount is 0 might be safer if API expects the fields
      final int debitAccountNoDisc =
          (amountdiscInt != 0 && _selectedDebitAccountDisc != null)
              ? _selectedDebitAccountDisc!.accountNo
              : 0; // Or handle null if API allows
      final int creditAccountNoDisc =
          (amountdiscInt != 0 && _selectedCreditAccountDisc != null)
              ? _selectedCreditAccountDisc!.accountNo
              : 0; // Or handle null if API allows

      // Prepare body, ensure keys match API ('Value_Disc', 'Akun_Debit_disc' etc.)
      final body = json.encode({
        "TransDate": formattedDate,
        "Description": description,
        "Akun_Debit": debitAccountNo,
        "Akun_Credit": creditAccountNo,
        // Use names consistent with your API expectation
        "Akun_Debit_disc": debitAccountNoDisc,
        "Akun_Credit_disc": creditAccountNoDisc,
        "Value": amountInt,
        "Value_Disc": amountdiscInt,
      });

      final url = Uri.parse('$baseUrl/api/API/SubmitJPB');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("Submitting JPB: $body");

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Submit Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase Journal entry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String serverMessage = response.reasonPhrase ?? 'Submission Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Submit Failed Body: ${response.body}");
        throw Exception(
          'Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _submitError = "Submission request timed out.";
    } on http.ClientException catch (e) {
      _submitError = "Network error during submission: ${e.message}.";
    } catch (e) {
      print("Error submitting purchase journal entry: $e");
      _submitError = "An error occurred during submission: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Purchase Journal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Date Selection (No changes) ---
              Text(
                'Transaction Date:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // --- Description Input (No changes) ---
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter transaction description',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Accounts Loading/Error State ---
              if (_isLoadingAccounts)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_accountError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Error loading accounts: $_accountError',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                // --- Debit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccount,
                  itemAsString:
                      (Account acc) => acc.accountName, // Display name
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Account",
                      hintText: "Select Debit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true, // Keep search box enabled
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ), // Simplified hint
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedDebitAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a debit account.'
                              : null,
                ),
                SizedBox(height: 16),

                // --- Credit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccount,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Account",
                      hintText: "Select Credit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedCreditAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a credit account.'
                              : null,
                ),
                SizedBox(height: 16),

                // --- Discount Debit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Disc Account (Optional)",
                      hintText: "Select Debit Disc Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedDebitAccountDisc = newValue;
                    });
                  },
                  // No validator - optional field
                ),
                SizedBox(height: 16),

                // --- Discount Credit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Disc Account (Optional)",
                      hintText: "Select Credit Disc Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedCreditAccountDisc = newValue;
                    });
                  },
                  // No validator - optional field
                ),
                SizedBox(height: 16),
              ],

              // --- Value Input (No changes) ---
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount for Value.';
                  }
                  final cleanedValue = value.replaceAll('.', '');
                  final number = double.tryParse(cleanedValue);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid positive amount for Value.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Discount Value Input (No changes) ---
              TextFormField(
                controller: _valueDiscController,
                decoration: InputDecoration(
                  labelText: 'Value Disc (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter discount amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
              ),
              SizedBox(height: 24),

              // --- Submission Error / Button (No changes) ---
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child:
                    _isSubmitting
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text('Submit Entry'),
                          onPressed: _submitJournalEntry,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
// ================================================================
// END OF ADD PURCHASE JOURNAL ENTRY PAGE
// ================================================================

class AddMemorialJournalEntryPage extends StatefulWidget {
  @override
  _AddMemorialJournalEntryPageState createState() =>
      _AddMemorialJournalEntryPageState();
}

class _AddMemorialJournalEntryPageState
    extends State<AddMemorialJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime? _selectedDate;
  List<Account> _accountsList = [];
  Account? _selectedDebitAccount;
  Account? _selectedCreditAccount;

  bool _isLoadingAccounts = true;
  String? _accountError;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
      _accountError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }
      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _accountsList =
              data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
          _isLoadingAccounts = false;
        });
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      _accountError = "Fetching accounts timed out.";
    } on http.ClientException catch (e) {
      _accountError = "Network error fetching accounts: ${e.message}.";
    } catch (e) {
      print("Error fetching accounts: $e");
      _accountError = "An error occurred fetching accounts: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitJournalEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null ||
        _selectedDebitAccount == null ||
        _selectedCreditAccount == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all required fields.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
    if (_selectedDebitAccount!.accountNo == _selectedCreditAccount!.accountNo) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debit and Credit accounts cannot be the same.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }

      // --- CHANGE 1: Format date as yyyy-MM-dd ---
      final String formattedDate = DateFormat(
        "yyyy-MM-dd",
      ).format(_selectedDate!);

      final String description = _descriptionController.text;
      final int debitAccountNo = _selectedDebitAccount!.accountNo;
      final int creditAccountNo = _selectedCreditAccount!.accountNo;
      final String amountString = _amountController.text.replaceAll(
        '.',
        '',
      ); // Remove separators
      final double? amount = double.tryParse(amountString);

      if (amount == null || amount <= 0) {
        throw Exception('Invalid or zero amount entered.');
      }

      // --- CHANGE 2: Convert amount to int for the body ---
      final int amountInt = amount.toInt();

      final body = json.encode({
        "TransDate": formattedDate, // Use date-only format
        "Description": description,
        "Akun_Debit": debitAccountNo,
        "Akun_Credit": creditAccountNo,
        "Debit": amountInt, // Send as integer
        "Credit": amountInt, // Send as integer
      });

      final url = Uri.parse('$baseUrl/api/API/SubmitJM');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("Submitting JM: $body"); // Check the body format before sending

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Submit Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal entry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String serverMessage = response.reasonPhrase ?? 'Submission Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        // Include response body in error for better debugging
        print("Submit Failed Body: ${response.body}");
        throw Exception(
          'Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _submitError = "Submission request timed out.";
    } on http.ClientException catch (e) {
      _submitError = "Network error during submission: ${e.message}.";
    } catch (e) {
      print("Error submitting journal entry: $e");
      _submitError = "An error occurred during submission: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Memorial Journal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Date:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter transaction description',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_isLoadingAccounts)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_accountError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Error loading accounts: $_accountError',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                // --- Debit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccount,
                  itemAsString:
                      (Account acc) => acc.accountName, // Display name
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Account",
                      hintText: "Select Debit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true, // Keep search box enabled
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ), // Simplified hint
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedDebitAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a debit account.'
                              : null,
                ),
                SizedBox(height: 16),

                // --- Credit Account Dropdown (USING DropdownSearch - filterFn removed) ---
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccount,
                  itemAsString: (Account acc) => acc.accountName,
                  compareFn:
                      (Account? i, Account? s) => i?.accountNo == s?.accountNo,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Account",
                      hintText: "Select Credit Account",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: "Search account...",
                      ),
                      autofocus: true,
                    ),
                    itemBuilder:
                        (context, account, isSelected) => ListTile(
                          title: Text(account.accountName),
                          selected: isSelected,
                        ),
                    // filterFn: (account, filter) { ... }, // <-- REMOVED filterFn from here
                    menuProps: MenuProps(),
                  ),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedCreditAccount = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a credit account.'
                              : null,
                ),
                SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Debit/Credit)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount.';
                  }
                  final cleanedValue = value.replaceAll('.', '');
                  final number = double.tryParse(cleanedValue);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid positive amount.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child:
                    _isSubmitting
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text('Submit Entry'),
                          onPressed: _submitJournalEntry,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MEMORIAL JOURNAL PAGE (Using "Load More" Pagination)
// ================================================================
class MemorialJournalPage extends StatefulWidget {
  @override
  _MemorialJournalPageState createState() => _MemorialJournalPageState();
}

class _MemorialJournalPageState extends State<MemorialJournalPage> {
  List<MemorialJournalEntry> _allApiEntriesMaster = []; // Master list from API
  List<MemorialJournalEntry> _processedClientSideEntries =
      []; // After all client-side filters & sort
  List<MemorialJournalEntry> _filteredEntries =
      []; // UI List: Paginated subset of _processedClientSideEntries

  bool _isLoadingApi = false;
  String? _error;

  // Date Filters
  DateTime? _startDate;
  DateTime? _endDate;

  // Client-side Pagination State
  final int _clientPageSize = 15; // How many items to show per "page"
  int _clientCurrentPage =
      1; // Current page *number* of client-side paginated data being displayed
  bool _clientHasMoreDataToDisplay =
      false; // If there are more items in _processedClientSideEntries to show

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeServerSearchQuery =
      ''; // Query sent to server (if API supports it)

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    print("MJ_NO_CRUD: initState");
    _fetchApiDataAndProcessClientSide();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final newSearchQuery = _searchController.text.trim();
      if (_activeServerSearchQuery != newSearchQuery) {
        _activeServerSearchQuery = newSearchQuery;
        _fetchApiDataAndProcessClientSide();
      }
    });
  }

  Future<void> _fetchApiDataAndProcessClientSide() async {
    if (!mounted || _isLoadingApi) return;
    print("MJ_NO_CRUD: Fetching API. Search: '$_activeServerSearchQuery'");
    setState(() {
      _isLoadingApi = true;
      _error = null;
      _allApiEntriesMaster.clear();
      _processedClientSideEntries.clear();
      _filteredEntries.clear();
      _clientCurrentPage = 1;
      _clientHasMoreDataToDisplay = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      var queryParams = {
        if (_activeServerSearchQuery.isNotEmpty)
          'search': _activeServerSearchQuery,
      };
      final url = Uri.parse(
        '$baseUrl/api/API/getdataJM',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("MJ_NO_CRUD: Fetching API URL: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) return;
      if (response.statusCode == 200) {
        print("MJ_NO_CRUD: API success (200)");
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allApiEntriesMaster =
            data
                .map((jsonItem) => MemorialJournalEntry.fromJson(jsonItem))
                .toList();
        print(
          "MJ_NO_CRUD: Fetched ${_allApiEntriesMaster.length} total entries from API.",
        );
        _applyClientFiltersAndSortAndPaginate();
      } else {
        throw Exception(
          'Failed to load entries. Status: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print("MJ_NO_CRUD: EXCEPTION in _fetch: $e\n$s");
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoadingApi = false;
        });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          );
        }
      });
      _applyClientFiltersAndSortAndPaginate();
    }
  }

  void _clearDateFilters() {
    if (!mounted) return;
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyClientFiltersAndSortAndPaginate();
  }

  void _applyClientFiltersAndSortAndPaginate() {
    if (!mounted) return;
    print("MJ_NO_CRUD: Applying client filters, sort, and paginate.");

    List<MemorialJournalEntry> dateFilteredList =
        _allApiEntriesMaster.where((entry) {
          bool passesStartDate =
              _startDate == null || !entry.transDate.isBefore(_startDate!);
          bool passesEndDate =
              _endDate == null || !entry.transDate.isAfter(_endDate!);
          return passesStartDate && passesEndDate;
        }).toList();
    print("MJ_NO_CRUD: After date filter: ${dateFilteredList.length} entries.");

    dateFilteredList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.transDate.compareTo(b.transDate);
          break;
        case 1:
          compareResult = a.transNo.compareTo(b.transNo);
          break;
        case 2:
          compareResult = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          break;
        case 3:
          compareResult = a.debit.compareTo(b.debit);
          break;
        case 4:
          compareResult = a.credit.compareTo(b.credit);
          break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
    _processedClientSideEntries = dateFilteredList;
    print(
      "MJ_NO_CRUD: After sort: ${_processedClientSideEntries.length} entries.",
    );

    setState(() {
      // This setState will trigger UI update with the first page
      _clientCurrentPage = 1;
      _updatePaginatedDisplay();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyClientFiltersAndSortAndPaginate();
    });
  }

  void _updatePaginatedDisplay() {
    if (!mounted) return;
    print(
      "MJ_NO_CRUD: Updating paginated display. Client Page: $_clientCurrentPage, Processed count: ${_processedClientSideEntries.length}",
    );

    int startIndex = (_clientCurrentPage - 1) * _clientPageSize;
    int endIndex = startIndex + _clientPageSize;

    if (startIndex >= _processedClientSideEntries.length) {
      // This means we are trying to display a page beyond the available filtered data
      _filteredEntries =
          (_clientCurrentPage == 1)
              ? []
              : List.from(
                _filteredEntries,
              ); // Keep existing if not first page but no new items
      _clientHasMoreDataToDisplay = false;
    } else {
      if (endIndex > _processedClientSideEntries.length) {
        endIndex = _processedClientSideEntries.length;
      }
      if (_clientCurrentPage == 1) {
        // For the first page or after a filter/sort reset
        _filteredEntries = _processedClientSideEntries.sublist(
          startIndex,
          endIndex,
        );
      } else {
        // For "Load More", append
        _filteredEntries.addAll(
          _processedClientSideEntries.sublist(startIndex, endIndex),
        );
      }
      _clientHasMoreDataToDisplay =
          endIndex < _processedClientSideEntries.length;
    }
    print(
      "MJ_NO_CRUD: Displaying ${_filteredEntries.length} items. Client has more: $_clientHasMoreDataToDisplay",
    );
    // setState is called by the methods that call this if direct UI update is needed
  }

  void _loadMoreClientSide() {
    if (!mounted || !_clientHasMoreDataToDisplay || _isLoadingApi) return;
    print(
      "MJ_NO_CRUD: Loading more client side. Next client page will be: ${_clientCurrentPage + 1}",
    );
    setState(() {
      _clientCurrentPage++;
      _updatePaginatedDisplay(); // This will append the next slice
    });
  }

  // Action Handlers (Simplified - No Edit/Delete for this version)
  void _viewEntry(MemorialJournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMemorialJournalEntryPage(entryId: entry.id),
      ),
    );
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMemorialJournalEntryPage()),
    );
    if (result == true && mounted) {
      _fetchApiDataAndProcessClientSide();
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "MJ_NO_CRUD: build - _isLoadingApi: $_isLoadingApi, _filteredEntries.length: ${_filteredEntries.length}, _error: $_error",
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Memorial Journal (Client Filter)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed:
                _isLoadingApi
                    ? null
                    : () => _fetchApiDataAndProcessClientSide(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            /* ... Search TextField ... */ padding: const EdgeInsets.fromLTRB(
              12.0,
              12.0,
              12.0,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Trans. No or Description',
                hintText: 'Enter search term...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _activeServerSearchQuery = '';
                            _fetchApiDataAndProcessClientSide();
                          },
                        )
                        : null,
              ),
            ),
          ),
          _buildDateFilterControls(),
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add Memorial Journal',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateFilterControls() {
    /* ... Date Filter UI ... */
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final Color primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 0.0,
        alignment: WrapAlignment.center,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _startDate == null ? 'From Date' : formatter.format(_startDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, true),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _endDate == null ? 'To Date' : formatter.format(_endDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, false),
          ),
          if (_startDate != null || _endDate != null)
            ActionChip(
              avatar: Icon(Icons.clear, size: 16),
              label: Text('Clear Dates'),
              onPressed: _clearDateFilters,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildDataArea() {
    if (_isLoadingApi && _allApiEntriesMaster.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorWidget(_error!),
        ),
      );
    }
    if (_filteredEntries.isEmpty && !_isLoadingApi) {
      return Center(
        child: Text(
          (_activeServerSearchQuery.isNotEmpty ||
                  _startDate != null ||
                  _endDate != null)
              ? 'No entries found for current filters.'
              : 'No entries to display.',
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [_buildDataTable(), _buildPaginationControlsClientSide()],
      ),
    );
  }

  Widget _buildDataTable() {
    final List<DataColumn> columns = [
      DataColumn(
        label: Text('Date'),
        tooltip: 'Transaction Date',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Trans No'),
        tooltip: 'Transaction Number',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Description'),
        tooltip: 'Transaction Description',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Debit'),
        tooltip: 'Debit Amount',
        numeric: true,
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Credit'),
        tooltip: 'Credit Amount',
        numeric: true,
        onSort: _onSort,
      ) /*DataColumn(label: Text('Actions')),*/,
    ]; // Removed Actions column for simplicity
    final List<DataRow> rows =
        _filteredEntries.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(entry.formattedDate)),
              DataCell(Text(entry.transNo)),
              DataCell(Text(entry.description)),
              DataCell(Text(entry.formattedDebit)),
              DataCell(
                Text(entry.formattedCredit),
              ) /*DataCell( Row( mainAxisSize: MainAxisSize.min, children: [ IconButton(icon: Icon(Icons.visibility, size:20, color: Colors.grey), tooltip: 'View', onPressed: () => _viewEntry(entry)), ],),),*/,
            ],
            onSelectChanged: (selected) {
              if (selected ?? false) _viewEntry(entry);
            },
          );
        }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        showCheckboxColumn: true,
        columnSpacing: 15,
      ),
    );
  }

  Widget _buildPaginationControlsClientSide() {
    if (_isLoadingApi &&
        _allApiEntriesMaster.isNotEmpty &&
        _filteredEntries.length < _processedClientSideEntries.length) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_clientHasMoreDataToDisplay && !_isLoadingApi) {
      // Use the correct flag
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreClientSide, // Corrected call
            child: Text(
              'Load More (${_processedClientSideEntries.length - _filteredEntries.length} remaining)',
            ),
          ),
        ),
      );
    } else if (_allApiEntriesMaster.isNotEmpty &&
        !_clientHasMoreDataToDisplay &&
        !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("End of list", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
            SizedBox(height: 15),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed: () => _fetchApiDataAndProcessClientSide(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ================================================================
// END OF MEMORIAL JOURNAL PAGE
// ================================================================

// --- Other Placeholder Pages ---
class SalesJournalPage extends StatefulWidget {
  @override
  _SalesJournalPageState createState() => _SalesJournalPageState();
}

class _SalesJournalPageState extends State<SalesJournalPage> {
  List<SalesJournalEntry> _allApiEntriesMaster = [];
  List<SalesJournalEntry> _processedClientSideEntries = [];
  List<SalesJournalEntry> _filteredEntries = []; // This is your UI list

  bool _isLoadingApi = false;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;

  final int _clientPageSize = 15;
  int _clientCurrentPage = 1;
  bool _clientHasMoreDataToDisplay = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeServerSearchQuery = '';

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    print("SalesJournal_Corrected: initState");
    _fetchApiDataAndProcessClientSide();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final newSearchQuery = _searchController.text.trim();
      if (_activeServerSearchQuery != newSearchQuery) {
        _activeServerSearchQuery = newSearchQuery;
        _fetchApiDataAndProcessClientSide();
      }
    });
  }

  Future<void> _fetchApiDataAndProcessClientSide() async {
    if (!mounted || _isLoadingApi) return;
    print(
      "SalesJournal_Corrected: Fetching API. Search: '$_activeServerSearchQuery'",
    );
    setState(() {
      _isLoadingApi = true;
      _error = null;
      _allApiEntriesMaster.clear();
      _processedClientSideEntries.clear();
      _filteredEntries.clear();
      _clientCurrentPage = 1;
      _clientHasMoreDataToDisplay = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      var queryParams = {
        if (_activeServerSearchQuery.isNotEmpty)
          'search': _activeServerSearchQuery,
      };
      final url = Uri.parse(
        '$baseUrl/api/API/getdataJPN',
      ) // Sales Journal Endpoint
      .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("SalesJournal_Corrected: Fetching API URL: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) return;
      if (response.statusCode == 200) {
        print("SalesJournal_Corrected: API success (200)");
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allApiEntriesMaster =
            data
                .map((jsonItem) => SalesJournalEntry.fromJson(jsonItem))
                .toList(); // Use SalesJournalEntry.fromJson
        print(
          "SalesJournal_Corrected: Fetched ${_allApiEntriesMaster.length} total entries.",
        );
        _applyClientFiltersAndSortAndPaginate();
      } else {
        throw Exception(
          'Failed to load sales entries. Status: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print("SalesJournal_Corrected: EXCEPTION in _fetch: $e\n$s");
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoadingApi = false;
        });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          );
        }
      });
      _applyClientFiltersAndSortAndPaginate();
    }
  }

  void _clearFilter() {
    // This is your original clear for date filters
    if (!mounted) return;
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyClientFiltersAndSortAndPaginate();
  }

  void _applyClientFiltersAndSortAndPaginate() {
    if (!mounted) return;
    print(
      "SalesJournal_Corrected: Applying client filters, sort, and paginate.",
    );

    List<SalesJournalEntry> dateFilteredList =
        _allApiEntriesMaster.where((entry) {
          bool passesStartDate =
              _startDate == null || !entry.transDate.isBefore(_startDate!);
          bool passesEndDate =
              _endDate == null || !entry.transDate.isAfter(_endDate!);
          return passesStartDate && passesEndDate;
        }).toList();
    print(
      "SalesJournal_Corrected: After date filter: ${dateFilteredList.length} entries.",
    );

    // Sort the dateFilteredList
    dateFilteredList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.transDate.compareTo(b.transDate);
          break;
        case 1:
          compareResult = a.transNo.compareTo(b.transNo);
          break;
        case 2:
          compareResult = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          break;
        // --- CORRECTED: Use Value and ValueDisc for sorting as per SalesJournalEntry model ---
        case 3:
          compareResult = a.Value.compareTo(b.Value);
          break;
        case 4:
          compareResult = a.ValueDisc.compareTo(b.ValueDisc);
          break;
        // ------------------------------------------------------------------------------------
      }
      return _sortAscending ? compareResult : -compareResult;
    });
    _processedClientSideEntries = dateFilteredList;
    print(
      "SalesJournal_Corrected: After sort: ${_processedClientSideEntries.length} entries.",
    );

    setState(() {
      _clientCurrentPage = 1;
      _updatePaginatedUiList();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyClientFiltersAndSortAndPaginate();
    });
  }

  void _updatePaginatedUiList() {
    if (!mounted) return;
    print(
      "SalesJournal_Corrected: Updating paginated display. Client Page: $_clientCurrentPage, Processed: ${_processedClientSideEntries.length}",
    );

    int startIndex = (_clientCurrentPage - 1) * _clientPageSize;
    int endIndex = startIndex + _clientPageSize;

    List<SalesJournalEntry> nextPageItems = [];

    if (startIndex < _processedClientSideEntries.length) {
      if (endIndex > _processedClientSideEntries.length) {
        endIndex = _processedClientSideEntries.length;
      }
      nextPageItems = _processedClientSideEntries.sublist(startIndex, endIndex);
    }

    setState(() {
      // This setState updates the UI list
      if (_clientCurrentPage == 1) {
        _filteredEntries = nextPageItems;
      } else {
        _filteredEntries.addAll(nextPageItems);
      }
      _clientHasMoreDataToDisplay =
          endIndex < _processedClientSideEntries.length;
      print(
        "SalesJournal_Corrected: Displaying ${_filteredEntries.length}. Client has more: $_clientHasMoreDataToDisplay",
      );
    });
  }

  void _loadMoreClientSide() {
    if (!mounted || !_clientHasMoreDataToDisplay || _isLoadingApi) return;
    print(
      "SalesJournal_Corrected: Loading more. Next client page will be: ${_clientCurrentPage + 1}",
    );
    // _clientCurrentPage is incremented *before* calling _updatePaginatedUiList
    _clientCurrentPage++;
    _updatePaginatedUiList(); // This will append the next slice
  }

  // Action Handlers
  void _viewEntry(SalesJournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSalesJournalEntryPage(entryId: entry.id),
      ),
    );
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSalesJournalEntryPage()),
    );
    if (result == true && mounted) {
      _fetchApiDataAndProcessClientSide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Journal'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed:
                _isLoadingApi
                    ? null
                    : () => _fetchApiDataAndProcessClientSide(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Trans. No or Description',
                hintText: 'Enter search term...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _activeServerSearchQuery = '';
                            _fetchApiDataAndProcessClientSide();
                          },
                        )
                        : null,
              ),
            ),
          ),
          _buildDateFilterControls(),
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add Sales Journal',
        child: Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDateFilterControls() {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final Color primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 0.0,
        alignment: WrapAlignment.center,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _startDate == null ? 'From Date' : formatter.format(_startDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, true),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _endDate == null ? 'To Date' : formatter.format(_endDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, false),
          ),
          if (_startDate != null || _endDate != null)
            ActionChip(
              avatar: Icon(Icons.clear, size: 16),
              label: Text('Clear Dates'),
              onPressed: _clearFilter,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildDataArea() {
    if (_isLoadingApi && _allApiEntriesMaster.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorWidget(_error!),
        ),
      );
    }
    if (_filteredEntries.isEmpty && !_isLoadingApi) {
      return Center(
        child: Text(
          (_activeServerSearchQuery.isNotEmpty ||
                  _startDate != null ||
                  _endDate != null)
              ? 'No entries found for current filters.'
              : 'No entries to display.',
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [_buildDataTable(), _buildPaginationControlsClientSide()],
      ),
    );
  }

  Widget _buildDataTable() {
    // --- CORRECTED: Use SalesJournalEntry fields for columns and cells ---
    final List<DataColumn> columns = [
      DataColumn(
        label: Text('Date'),
        tooltip: 'Transaction Date',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Trans No'),
        tooltip: 'Transaction Number',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Description'),
        tooltip: 'Transaction Description',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Value'),
        tooltip: 'Transaction Value',
        numeric: true,
        onSort: _onSort,
      ), // Corrected Header
      DataColumn(
        label: Text('Discount'),
        tooltip: 'Discount Value',
        numeric: true,
        onSort: _onSort,
      ), // Corrected Header
      // DataColumn(label: Text('Actions')), // Removed actions as per request
    ];
    final List<DataRow> rows =
        _filteredEntries.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(entry.formattedDate)),
              DataCell(Text(entry.transNo)),
              DataCell(Text(entry.description)),
              DataCell(
                Text(entry.formattedValue),
              ), // Corrected: Use formattedValue
              DataCell(
                Text(entry.formattedValueDisc),
              ), // Corrected: Use formattedValueDisc
              // DataCell(Text("View")), // Placeholder for actions if needed later
            ],
            onSelectChanged: (selected) {
              if (selected ?? false) _viewEntry(entry);
            },
          );
        }).toList();
    // -------------------------------------------------------------------
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        showCheckboxColumn: true,
        columnSpacing: 15,
      ),
    );
  }

  Widget _buildPaginationControlsClientSide() {
    if (_isLoadingApi &&
        _allApiEntriesMaster.isNotEmpty &&
        _filteredEntries.length < _processedClientSideEntries.length) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_clientHasMoreDataToDisplay && !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreClientSide,
            child: Text(
              'Load More (${_processedClientSideEntries.length - _filteredEntries.length} remaining)',
            ), // Show remaining from processed list
          ),
        ),
      );
    } else if (_allApiEntriesMaster.isNotEmpty &&
        !_clientHasMoreDataToDisplay &&
        !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("End of list", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
            SizedBox(height: 15),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed: () => _fetchApiDataAndProcessClientSide(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchasingJournalPage extends StatefulWidget {
  @override
  _PurchasingJournalPageState createState() => _PurchasingJournalPageState();
}

class _PurchasingJournalPageState extends State<PurchasingJournalPage> {
  List<PurchaseJournalEntry> _allEntries =
      []; // This will now be the MASTER list from API
  List<PurchaseJournalEntry> _processedForDisplay =
      []; // List after date filter & sort on _allEntries
  List<PurchaseJournalEntry> _filteredEntries =
      []; // Your UI List: Paginated subset of _processedForDisplay

  bool _isLoading = true; // Main loading for API fetch
  // _isFetchingMore is not strictly needed for client-side pagination button,
  // but we can use _isLoading to disable the button during any processing.
  String? _error;

  // Date Filters
  DateTime? _startDate;
  DateTime? _endDate;

  // Client-side pagination state
  // _currentPage will now refer to the client-side page of _processedForDisplay
  int _currentPage = 1;
  final int _pageSize = 15; // Your original _pageSize, now for client-side view
  bool _hasMoreData =
      false; // For client-side: if _processedForDisplay has more items

  // Search (Server-side, if API supports it)
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeServerSearchQuery = '';

  // Sorting
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    print("PurchaseJournal_ClientSide_YourStruct: initState");
    _fetchJournalEntriesFromServer(
      isFullRefresh: true,
    ); // Changed name for clarity
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final newSearchQuery = _searchController.text.trim();
      if (_activeServerSearchQuery != newSearchQuery) {
        _activeServerSearchQuery = newSearchQuery;
        _fetchJournalEntriesFromServer(isFullRefresh: true);
      }
    });
  }

  // Renamed your original _fetchJournalEntries to clarify it fetches ALL from server
  Future<void> _fetchJournalEntriesFromServer({
    required bool isFullRefresh,
  }) async {
    if (!mounted || (_isLoading && !isFullRefresh)) return;
    print(
      "PurchaseJournal_ClientSide_YourStruct: Fetching ALL from API. Refresh: $isFullRefresh, Search: '$_activeServerSearchQuery'",
    );
    setState(() {
      _isLoading = true;
      _error = null;
      if (isFullRefresh) {
        _allEntries.clear(); // Clear the master API list
        _processedForDisplay.clear();
        _filteredEntries.clear(); // Clear the UI list
        _currentPage = 1; // Reset client-side page
        _hasMoreData = false; // Will be set by _updatePaginatedUiList
      }
      // _isFetchingMore = false; // Not needed if using single _isLoading
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      var queryParams = {
        if (_activeServerSearchQuery.isNotEmpty)
          'search': _activeServerSearchQuery,
      };
      final url = Uri.parse(
        '$baseUrl/api/API/getdataJPB',
      ) // Purchase Journal Endpoint
      .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("PurchaseJournal_ClientSide_YourStruct: Fetching API URL: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) return;
      if (response.statusCode == 200) {
        print("PurchaseJournal_ClientSide_YourStruct: API success (200)");
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allEntries =
            data
                .map((jsonItem) => PurchaseJournalEntry.fromJson(jsonItem))
                .toList();
        print(
          "PurchaseJournal_ClientSide_YourStruct: Fetched ${_allEntries.length} total entries from API.",
        );
        _applyFilter(); // This will now apply client filters, sort, and set up first page display
      } else {
        throw Exception(
          'Failed to load purchase entries. Status: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print(
        "PurchaseJournal_ClientSide_YourStruct: EXCEPTION in _fetch: $e\n$s",
      );
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false; /* _isFetchingMore = false; */
        });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        // Set the date filter state
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          );
        }
      });
      _applyFilter(); // Re-process the _allEntries list
    }
  }

  void _clearFilter() {
    // Your original _clearFilter
    if (!mounted) return;
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilter(); // Re-process the _allEntries list
  }

  // _applyFilter now processes _allEntries, sorts, and sets up the first client-side page
  void _applyFilter() {
    if (!mounted) return;
    print(
      "PurchaseJournal_ClientSide_YourStruct: Applying client filters and sort.",
    );

    // 1. Start with all entries fetched from API
    List<PurchaseJournalEntry> dateFilteredList =
        _allEntries.where((entry) {
          bool passesStartDate =
              _startDate == null || !entry.transDate.isBefore(_startDate!);
          bool passesEndDate =
              _endDate == null || !entry.transDate.isAfter(_endDate!);
          return passesStartDate && passesEndDate;
        }).toList();
    print(
      "PurchaseJournal_ClientSide_YourStruct: After date filter: ${dateFilteredList.length} entries.",
    );

    // 2. Sort the dateFilteredList (your original _applySort logic is here)
    dateFilteredList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.transDate.compareTo(b.transDate);
          break;
        case 1:
          compareResult = a.transNo.compareTo(b.transNo);
          break;
        case 2:
          compareResult = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          break;
        case 3:
          compareResult = a.Value.compareTo(b.Value);
          break;
        case 4:
          compareResult = a.ValueDisc.compareTo(b.ValueDisc);
          break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
    _processedForDisplay =
        dateFilteredList; // Store the fully client-processed list
    print(
      "PurchaseJournal_ClientSide_YourStruct: After sort: ${_processedForDisplay.length} entries.",
    );

    // 3. Reset client-side pagination and display the first "page" of _processedForDisplay
    setState(() {
      _currentPage = 1; // Reset to page 1 of the NEWLY processed list
      _updatePaginatedUiList(); // Update _filteredEntries (UI list)
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    setState(() {
      // For UI sort indicator update
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyFilter(); // Re-apply filters which will also re-sort and reset pagination
    });
  }

  // Updates _filteredEntries (your UI list) based on _processedForDisplay and _currentPage
  void _updatePaginatedUiList() {
    if (!mounted) return;
    print(
      "PurchaseJournal_ClientSide_YourStruct: Updating paginated display. Client Page: $_currentPage, Processed count: ${_processedForDisplay.length}",
    );

    int startIndex =
        (_currentPage - 1) * _pageSize; // Use _pageSize for client-side view
    int endIndex = startIndex + _pageSize;

    List<PurchaseJournalEntry> nextPageItems = [];

    if (startIndex < _processedForDisplay.length) {
      if (endIndex > _processedForDisplay.length) {
        endIndex = _processedForDisplay.length;
      }
      nextPageItems = _processedForDisplay.sublist(startIndex, endIndex);
    }

    // This logic ensures correct append vs. replace for _filteredEntries
    // If _currentPage is 1, it means we are displaying the first page (after filter/sort/initial)
    // If _currentPage > 1, it means "Load More" was pressed, so we append.
    if (_currentPage == 1) {
      _filteredEntries = nextPageItems;
    } else {
      _filteredEntries.addAll(nextPageItems); // Append for "Load More"
    }
    _hasMoreData = endIndex < _processedForDisplay.length;

    print(
      "PurchaseJournal_ClientSide_YourStruct: Displaying ${_filteredEntries.length} items. Client has more: $_hasMoreData",
    );
    // setState is called by the methods that call this (_applyFilter or _loadMoreClientSide)
  }

  void _loadMoreClientSide() {
    // New function for "Load More" button
    if (!mounted || !_hasMoreData || _isLoading) return;
    print(
      "PurchaseJournal_ClientSide_YourStruct: Loading more client side. Next client page will be: ${_currentPage + 1}",
    );
    setState(() {
      _currentPage++; // Increment the client-side page we want to display up to
      _updatePaginatedUiList(); // This will append the next slice to _filteredEntries
    });
  }

  // Action Handlers (View, Add - NO Edit/Delete as requested)
  void _viewEntry(PurchaseJournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPurchaseJournalEntryPage(entryId: entry.id),
      ),
    );
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPurchaseJournalEntryPage()),
    );
    if (result == true && mounted) {
      _fetchJournalEntriesFromServer(isFullRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "PurchaseJournal_ClientSide_YourStruct: build - _isLoading: $_isLoading, _filteredEntries.length: ${_filteredEntries.length}, _error: $_error",
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchasing Journal'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed:
                _isLoading
                    ? null
                    : () => _fetchJournalEntriesFromServer(isFullRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Trans. No or Description',
                hintText: 'Enter search term...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _activeServerSearchQuery = '';
                            _fetchJournalEntriesFromServer(isFullRefresh: true);
                          },
                        )
                        : null,
              ),
            ),
          ),
          _buildDateFilterControls(), // Using your original method name
          Expanded(child: _buildBodyDataArea()), // Renamed for clarity
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add Purchase Journal',
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildDateFilterControls() {
    // Renamed from _buildDateFilterRow
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final Color primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 0.0,
        alignment: WrapAlignment.center,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _startDate == null ? 'From Date' : formatter.format(_startDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, true),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(
              _endDate == null ? 'To Date' : formatter.format(_endDate!),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => _selectDate(context, false),
          ),
          if (_startDate != null || _endDate != null)
            ActionChip(
              avatar: Icon(Icons.clear, size: 16),
              label: Text('Clear Dates'),
              onPressed: _clearFilter,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildBodyDataArea() {
    // Renamed from _buildBody
    if (_isLoading && _allEntries.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorWidget(_error!),
        ),
      );
    }
    if (_filteredEntries.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          (_activeServerSearchQuery.isNotEmpty ||
                  _startDate != null ||
                  _endDate != null)
              ? 'No entries found for current filters.'
              : 'No entries to display.',
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDataTable(),
          _buildPaginationControls(), // Using your original method name
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    // Use PurchaseJournalEntry fields for columns and cells
    final List<DataColumn> columns = [
      DataColumn(
        label: Text('Date'),
        tooltip: 'Transaction Date',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Trans No'),
        tooltip: 'Transaction Number',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Description'),
        tooltip: 'Transaction Description',
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Value'),
        tooltip: 'Value Amount',
        numeric: true,
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Discount'),
        tooltip: 'Discount Amount',
        numeric: true,
        onSort: _onSort,
      ) /*DataColumn(label: Text('Actions')),*/,
    ]; // Removed Actions for now
    final List<DataRow> rows =
        _filteredEntries.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(entry.formattedDate)),
              DataCell(Text(entry.transNo)),
              DataCell(Text(entry.description)),
              DataCell(Text(entry.formattedValue)),
              DataCell(
                Text(entry.formattedValueDisc),
              ) /*DataCell(Text("View")),*/,
            ],
            onSelectChanged: (selected) {
              if (selected ?? false) _viewEntry(entry);
            },
          );
        }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        showCheckboxColumn: true,
        columnSpacing: 15,
      ),
    );
  }

  Widget _buildPaginationControls() {
    // Kept your original method name
    // Show loader if API is fetching (isLoading) AND some data is already displayed (not initial load)
    if (_isLoading &&
        _allEntries.isNotEmpty &&
        _filteredEntries.length < _processedForDisplay.length) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasMoreData && !_isLoading) {
      // Use _hasMoreData (client-side flag)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ElevatedButton(
            onPressed:
                _loadMoreClientSide, // Call the new client-side load more
            child: Text(
              'Load More (${_processedForDisplay.length - _filteredEntries.length} remaining)',
            ),
          ),
        ),
      );
    } else if (_allEntries.isNotEmpty && !_hasMoreData && !_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("End of list", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
            SizedBox(height: 15),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed:
                  () => _fetchJournalEntriesFromServer(isFullRefresh: true),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// START OF DOWNLOAD REPORT PAGE & FILTER PAGES
// ================================================================
class DownloadReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Report')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('Trial Balance', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrialBalanceFilterPage(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.assessment_outlined, color: Colors.green),
            title: Text('Profit and Loss', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfitLossFilterPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.monetization_on, color: Colors.green),
            title: Text('Cashflow Report', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CashflowFilterPage()),
              );
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}

class TrialBalanceFilterPage extends StatefulWidget {
  @override
  _TrialBalanceFilterPageState createState() => _TrialBalanceFilterPageState();
}

class _TrialBalanceFilterPageState extends State<TrialBalanceFilterPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  int _selectedMonth = DateTime.now().month;
  bool _isYearly = true;
  bool _isPreview = true;
  bool _isLoading = false;
  String? _downloadError;

  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'name': 'January'},
    {'value': 2, 'name': 'February'},
    {'value': 3, 'name': 'March'},
    {'value': 4, 'name': 'April'},
    {'value': 5, 'name': 'May'},
    {'value': 6, 'name': 'June'},
    {'value': 7, 'name': 'July'},
    {'value': 8, 'name': 'August'},
    {'value': 9, 'name': 'September'},
    {'value': 10, 'name': 'October'},
    {'value': 11, 'name': 'November'},
    {'value': 12, 'name': 'December'},
  ];

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _downloadError = null;
    });
    String filePath = '';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      final int? year = int.tryParse(_yearController.text);
      if (year == null) throw Exception('Invalid Year entered.');

      final String reportNameForTitle = 'Trial Balance';
      final String previewStatus = _isPreview ? 'Preview' : 'Closed';
      final String endpointPath =
          _isPreview ? '/api/API/GeneratePreviewTB' : '/api/API/GeneratePdfTB';
      final url = Uri.parse('$baseUrl$endpointPath');
      final Map<String, dynamic> bodyMap = {
        "year": year,
        "month": _isYearly ? 0 : _selectedMonth,
        "isYearly": _isYearly,
      };
      final String requestBody = json.encode(bodyMap);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
      };
      print("--- FLUTTER REQUEST (Trial Balance - View) ---");
      print("URL: $url");
      print("Headers: $headers");
      print("Body: $requestBody");
      print("--- END FLUTTER REQUEST ---");
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        if (bytes.isEmpty) throw Exception('Received empty file from server.');
        final tempDir = await getTemporaryDirectory();
        final String monthString =
            _isYearly
                ? "Yearly"
                : DateFormat('MMM').format(DateTime(0, _selectedMonth));
        final String filename =
            '${reportNameForTitle.replaceAll(' ', '_')}_${year}_${monthString}_$previewStatus.pdf';
        final File file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);
        filePath = file.path;
        print('PDF saved temporarily to ${filePath}');

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerPage(
                  filePath: filePath,
                  reportName:
                      '$reportNameForTitle ($previewStatus $year - $monthString)',
                ),
          ),
        );
      } else {
        String serverMessage = response.reasonPhrase ?? 'Download Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Download Failed Body for Trial Balance: ${response.body}");
        throw Exception(
          'Failed to download report. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _downloadError = "Request timed out while generating report.";
    } on FileSystemException catch (e) {
      _downloadError = "Could not save temporary file: ${e.message}";
      print("FileSystemException saving report: $e");
    } catch (e) {
      print("Error downloading Trial Balance report: $e");
      _downloadError = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trial Balance Report')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure Report:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a year.';
                  if (value.length != 4) return 'Please enter a 4-digit year.';
                  if (int.tryParse(value) == null) return 'Invalid year.';
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Yearly Report'),
                value: _isYearly,
                onChanged: (bool value) {
                  setState(() {
                    _isYearly = value;
                  });
                },
                secondary: Icon(
                  _isYearly ? Icons.calendar_month : Icons.date_range,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 8),
              if (!_isYearly) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items:
                      _months.map((Map<String, dynamic> month) {
                        return DropdownMenuItem<int>(
                          value: month['value'],
                          child: Text(month['name']),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (!_isYearly && value == null)
                      return 'Please select a month.';
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],
              SwitchListTile(
                title: Text('Preview Version'),
                subtitle: Text(
                  _isPreview
                      ? 'Get latest preview data'
                      : 'Get final closed data',
                ),
                value: _isPreview,
                onChanged: (bool value) {
                  setState(() {
                    _isPreview = value;
                  });
                },
                secondary: Icon(
                  _isPreview ? Icons.visibility : Icons.lock_clock,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 30),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _downloadError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('Generate & View PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _downloadReport(context),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfitLossFilterPage extends StatefulWidget {
  @override
  _ProfitLossFilterPageState createState() => _ProfitLossFilterPageState();
}

class _ProfitLossFilterPageState extends State<ProfitLossFilterPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  int _selectedMonth = DateTime.now().month;
  bool _isYearly = true;
  bool _isPreview = true;
  bool _isLoading = false;
  String? _downloadError;

  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'name': 'January'},
    {'value': 2, 'name': 'February'},
    {'value': 3, 'name': 'March'},
    {'value': 4, 'name': 'April'},
    {'value': 5, 'name': 'May'},
    {'value': 6, 'name': 'June'},
    {'value': 7, 'name': 'July'},
    {'value': 8, 'name': 'August'},
    {'value': 9, 'name': 'September'},
    {'value': 10, 'name': 'October'},
    {'value': 11, 'name': 'November'},
    {'value': 12, 'name': 'December'},
  ];

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _downloadError = null;
    });
    String filePath = '';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      final int? year = int.tryParse(_yearController.text);
      if (year == null) throw Exception('Invalid Year entered.');

      final String reportNameForTitle = 'Profit & Loss';
      final String previewStatus = _isPreview ? 'Preview' : 'Closed';
      final String endpointPath =
          _isPreview ? '/api/API/GeneratePreviewLR' : '/api/API/GeneratePdfLR';
      final url = Uri.parse('$baseUrl$endpointPath');
      final Map<String, dynamic> bodyMap = {
        "year": year,
        "month": _isYearly ? 0 : _selectedMonth,
        "isYearly": _isYearly,
      };
      final String requestBody = json.encode(bodyMap);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
      };
      print("--- FLUTTER REQUEST (P&L - View) ---");
      print("URL: $url");
      print("Headers: $headers");
      print("Body: $requestBody");
      print("--- END FLUTTER REQUEST ---");
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        if (bytes.isEmpty) throw Exception('Received empty file from server.');
        final tempDir = await getTemporaryDirectory();
        final String monthString =
            _isYearly
                ? "Yearly"
                : DateFormat('MMM').format(DateTime(0, _selectedMonth));
        final String filename =
            '${reportNameForTitle.replaceAll(' ', '_').replaceAll('&', 'and')}_${year}_${monthString}_$previewStatus.pdf';
        final File file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);
        filePath = file.path;
        print('PDF saved temporarily to ${filePath}');

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerPage(
                  filePath: filePath,
                  reportName:
                      '$reportNameForTitle ($previewStatus $year - $monthString)',
                ),
          ),
        );
      } else {
        String serverMessage = response.reasonPhrase ?? 'Download Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Download Failed Body for P&L: ${response.body}");
        throw Exception(
          'Failed to download report. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _downloadError = "Request timed out while generating report.";
    } on FileSystemException catch (e) {
      _downloadError = "Could not save temporary file: ${e.message}";
      print("FileSystemException saving report: $e");
    } catch (e) {
      print("Error downloading P&L report: $e");
      _downloadError = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profit and Loss Report')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure Report:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a year.';
                  if (value.length != 4) return 'Please enter a 4-digit year.';
                  if (int.tryParse(value) == null) return 'Invalid year.';
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Yearly Report'),
                subtitle: Text(
                  _isYearly
                      ? 'Covers the entire selected year'
                      : 'Select specific month below',
                ),
                value: _isYearly,
                onChanged: (bool value) {
                  setState(() {
                    _isYearly = value;
                  });
                },
                secondary: Icon(
                  _isYearly ? Icons.calendar_month : Icons.date_range,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 8),
              if (!_isYearly) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items:
                      _months.map((Map<String, dynamic> month) {
                        return DropdownMenuItem<int>(
                          value: month['value'],
                          child: Text(month['name']),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (!_isYearly && value == null)
                      return 'Please select a month.';
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],
              SwitchListTile(
                title: Text('Preview Version'),
                subtitle: Text(
                  _isPreview
                      ? 'Get latest preview data'
                      : 'Get final closed data',
                ),
                value: _isPreview,
                onChanged: (bool value) {
                  setState(() {
                    _isPreview = value;
                  });
                },
                secondary: Icon(
                  _isPreview ? Icons.visibility : Icons.lock_clock,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 30),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _downloadError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('Generate & View PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _downloadReport(context),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class CashflowFilterPage extends StatefulWidget {
  @override
  _CashflowFilterPageState createState() => _CashflowFilterPageState();
}

class _CashflowFilterPageState extends State<CashflowFilterPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  int _selectedMonth = DateTime.now().month;
  bool _isYearly = true;
  bool _isPreview = true;
  bool _isLoading = false;
  String? _downloadError;

  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'name': 'January'},
    {'value': 2, 'name': 'February'},
    {'value': 3, 'name': 'March'},
    {'value': 4, 'name': 'April'},
    {'value': 5, 'name': 'May'},
    {'value': 6, 'name': 'June'},
    {'value': 7, 'name': 'July'},
    {'value': 8, 'name': 'August'},
    {'value': 9, 'name': 'September'},
    {'value': 10, 'name': 'October'},
    {'value': 11, 'name': 'November'},
    {'value': 12, 'name': 'December'},
  ];

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _downloadError = null;
    });
    String filePath = '';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');
      final int? year = int.tryParse(_yearController.text);
      if (year == null) throw Exception('Invalid Year entered.');

      final String reportNameForTitle = 'Cashflow';
      final String previewStatus = _isPreview ? 'Preview' : 'Closed';
      final String endpointPath =
          _isPreview
              ? '/api/API/GeneratePreviewCashflow'
              : '/api/API/GeneratePdfCashflow';
      final url = Uri.parse('$baseUrl$endpointPath');
      final Map<String, dynamic> bodyMap = {
        "year": year,
        "month": _isYearly ? 0 : _selectedMonth,
        "isYearly": _isYearly,
      };
      final String requestBody = json.encode(bodyMap);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
      };
      print("--- FLUTTER REQUEST (P&L - View) ---");
      print("URL: $url");
      print("Headers: $headers");
      print("Body: $requestBody");
      print("--- END FLUTTER REQUEST ---");
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        if (bytes.isEmpty) throw Exception('Received empty file from server.');
        final tempDir = await getTemporaryDirectory();
        final String monthString =
            _isYearly
                ? "Yearly"
                : DateFormat('MMM').format(DateTime(0, _selectedMonth));
        final String filename =
            '${reportNameForTitle.replaceAll(' ', '_').replaceAll('&', 'and')}_${year}_${monthString}_$previewStatus.pdf';
        final File file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);
        filePath = file.path;
        print('PDF saved temporarily to ${filePath}');

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerPage(
                  filePath: filePath,
                  reportName:
                      '$reportNameForTitle ($previewStatus $year - $monthString)',
                ),
          ),
        );
      } else {
        String serverMessage = response.reasonPhrase ?? 'Download Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Download Failed Body for P&L: ${response.body}");
        throw Exception(
          'Failed to download report. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _downloadError = "Request timed out while generating report.";
    } on FileSystemException catch (e) {
      _downloadError = "Could not save temporary file: ${e.message}";
      print("FileSystemException saving report: $e");
    } catch (e) {
      print("Error downloading Cashflow report: $e");
      _downloadError = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cashflow Report')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure Report:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a year.';
                  if (value.length != 4) return 'Please enter a 4-digit year.';
                  if (int.tryParse(value) == null) return 'Invalid year.';
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Yearly Report'),
                subtitle: Text(
                  _isYearly
                      ? 'Covers the entire selected year'
                      : 'Select specific month below',
                ),
                value: _isYearly,
                onChanged: (bool value) {
                  setState(() {
                    _isYearly = value;
                  });
                },
                secondary: Icon(
                  _isYearly ? Icons.calendar_month : Icons.date_range,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 8),
              if (!_isYearly) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items:
                      _months.map((Map<String, dynamic> month) {
                        return DropdownMenuItem<int>(
                          value: month['value'],
                          child: Text(month['name']),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (!_isYearly && value == null)
                      return 'Please select a month.';
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],
              SwitchListTile(
                title: Text('Preview Version'),
                subtitle: Text(
                  _isPreview
                      ? 'Get latest preview data'
                      : 'Get final closed data',
                ),
                value: _isPreview,
                onChanged: (bool value) {
                  setState(() {
                    _isPreview = value;
                  });
                },
                secondary: Icon(
                  _isPreview ? Icons.visibility : Icons.lock_clock,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 30),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _downloadError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('Generate & View PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _downloadReport(context),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// END OF DOWNLOAD REPORT PAGE & FILTER PAGES
// ================================================================

// --- Admin Menu Page (with Navigation to Account Settings) ---
class AdminMenuPage extends StatelessWidget {
  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Menu')),
      body: ListView(
        // Using ListView for a cleaner menu
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(
              Icons.manage_accounts,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('Account Settings', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _navigate(context, AccountSettingsPage()); // Navigate here
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.people_alt_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('User Settings', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to UserSettingsPage when created
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User Settings page not yet implemented.'),
                ),
              );
            },
          ),
          Divider(),
          // Add more admin options here
        ],
      ),
    );
  }
}

// ================================================================
// PDF VIEWER PAGE (with Save Button)
// ================================================================
class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String reportName;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.reportName,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  PDFViewController? _pdfViewController;
  bool _isSharing = false;

  Future<void> _shareOrSavePdf() async {
    if (_isSharing) return;
    setState(() {
      _isSharing = true;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final File fileToShare = File(widget.filePath);
      if (!await fileToShare.exists()) {
        throw Exception("File to share not found at ${widget.filePath}");
      }

      final box = context.findRenderObject() as RenderBox?;
      final shareResult = await Share.shareXFiles(
        [XFile(fileToShare.path)],
        text: 'Report: ${widget.reportName}',
        subject: widget.reportName,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );

      if (shareResult.status == ShareResultStatus.success) {
        print('Share sheet action successful for ${widget.reportName}');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File ready to be saved/shared!'),
              backgroundColor: Colors.green,
            ),
          );
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        print('Share sheet dismissed for ${widget.reportName}');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save/Share cancelled.'),
              backgroundColor: Colors.orange,
            ),
          );
      } else {
        print('Sharing failed for ${widget.reportName}: ${shareResult.status}');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open save/share options.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      print("Error sharing/saving PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportName),
        actions: <Widget>[
          _isSharing
              ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(Icons.share),
                tooltip: 'Share / Save a Copy',
                onPressed: _shareOrSavePdf,
              ),
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('${_currentPage + 1}/$_totalPages')),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              }
              print("PDF Rendered: $pages pages");
            },
            onError: (error) {
              print("PDF Error: $error");
              if (mounted) {
                setState(() {
                  _errorMessage = error.toString();
                });
              }
            },
            onPageError: (page, error) {
              print('PDF Page Error: page $page, error: $error');
              if (mounted) {
                setState(() {
                  _errorMessage = 'Error loading page $page: $error';
                });
              }
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              print('page change: $page/$total');
              if (mounted && page != null) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
          if (!_isReady && _errorMessage.isEmpty)
            Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading PDF: $_errorMessage',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _totalPages > 1
              ? FloatingActionButton.extended(
                label: Text("${_currentPage + 1}/$_totalPages"),
                icon: Icon(Icons.pages),
                onPressed: () async {
                  if (_pdfViewController != null) {
                    int nextPage = (_currentPage + 1) % _totalPages;
                    await _pdfViewController!.setPage(nextPage);
                  }
                },
              )
              : null,
    );
  }
}

// ================================================================
// END OF PDF VIEWER PAGE
// ================================================================

// ================================================================
// VIEW MEMORIAL JOURNAL ENTRY PAGE (Fetches its own details)
// ================================================================
class ViewMemorialJournalEntryPage extends StatefulWidget {
  final int entryId; // Receive only the ID

  const ViewMemorialJournalEntryPage({Key? key, required this.entryId})
    : super(key: key);

  @override
  _ViewMemorialJournalEntryPageState createState() =>
      _ViewMemorialJournalEntryPageState();
}

class _ViewMemorialJournalEntryPageState
    extends State<ViewMemorialJournalEntryPage> {
  MemorialJournalEntry? _entry; // To store the fetched entry details
  String? _debitAccountName;
  String? _creditAccountName;

  bool _isLoadingData = true; // Overall loading state for entry and accounts
  String? _fetchError;

  // Static cache for account list to avoid repeated full fetches
  static List<Account> _allAccountsCache = [];
  static bool _accountsCachePopulated = false;
  static bool _isFetchingAccountsGlobal =
      false; // Prevent concurrent global fetches

  @override
  void initState() {
    super.initState();
    _fetchEntryAndAccountDetails();
  }

  Future<void> _fetchAllAccountsIfNeeded() async {
    // Prevent re-fetching if already populated or another instance is fetching
    if (_accountsCachePopulated || _isFetchingAccountsGlobal) return;

    _isFetchingAccountsGlobal = true; // Mark that a fetch is in progress

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Auth token missing for accounts fetch.');

      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allAccountsCache =
            data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
        _accountsCachePopulated = true;
      } else {
        throw Exception(
          'Failed to load account list. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error fetching global account list: $e");
      // Don't set page-level error here, allow main data fetch to proceed
      // Individual account name lookups will then fail gracefully
    } finally {
      _isFetchingAccountsGlobal = false; // Mark fetch as complete
    }
  }

  Future<void> _fetchEntryAndAccountDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _fetchError = null;
    });

    try {
      // 1. Fetch all accounts if not already cached
      await _fetchAllAccountsIfNeeded();
      if (!mounted) return; // Check after await

      // 2. Fetch Specific Journal Entry Details
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      // Use POST as per your cURL example, with ID in query params
      final url = Uri.parse('$baseUrl/api/API/ViewJM?id=${widget.entryId}');
      final headers = {
        // 'Content-Type': 'application/json; charset=UTF-8', // POST usually has body, GET for view with query param might not need it.
        'Authorization': 'Bearer $token',
      };
      print("Fetching Journal Detail: $url");

      // Your cURL used POST, so we use POST here.
      // If your API for ViewJM is actually a GET, change http.post to http.get
      // and remove the empty body.
      final response = await http
          .post(
            url,
            headers:
                headers /*, body: json.encode({}) // Empty body if POST needs one */,
          )
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // The API returns a single JSON object, not a list
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final fetchedEntry = MemorialJournalEntry.fromJson(data);

        // 3. Get Account Names from Cache
        String? debitName = "Acc: ${fetchedEntry.akunDebit}"; // Default
        String? creditName = "Acc: ${fetchedEntry.akunCredit}"; // Default

        if (_accountsCachePopulated) {
          final debitAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunDebit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunDebit,
                  accountName: '(Unknown)',
                ),
          );
          debitName = '${debitAcc.accountName}';

          final creditAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunCredit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunCredit,
                  accountName: '(Unknown)',
                ),
          );
          creditName = '${creditAcc.accountName}';
        }

        if (mounted) {
          setState(() {
            _entry = fetchedEntry;
            _debitAccountName = debitName;
            _creditAccountName = creditName;
            _isLoadingData = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load journal entry details. Status: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      print("Error fetching entry details: $e");
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String? value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16),
              textAlign: isAmount ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      if (dateString.startsWith("0001-01-01")) return 'N/A (Default Date)';
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (e) {
      print("Error parsing date '$dateString': $e");
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading Journal...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fetchError != null || _entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading details: ${_fetchError ?? "Entry not found."}',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Entry is not null here
    final entry = _entry!;
    final String debitAmount = entry.formattedDebit; // Uses debitStr from model
    final String creditAmount =
        entry.formattedCredit; // Uses creditStr from model

    return Scaffold(
      appBar: AppBar(title: Text('Journal Detail: ${entry.transNo}')),
      body: RefreshIndicator(
        // Allow pull-to-refresh
        onRefresh: _fetchEntryAndAccountDetails,
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(), // Ensure scroll even if content fits
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'Entry Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Transaction No', entry.transNo),
                  _buildDetailRow('Transaction Date', entry.formattedDate),
                  _buildDetailRow('Description', entry.description),
                  Divider(height: 20),
                  _buildDetailRow(
                    'Debit Account',
                    _debitAccountName ?? entry.akunDebit.toString(),
                  ),
                  _buildDetailRow('Debit Amount', debitAmount, isAmount: true),
                  SizedBox(height: 10),
                  _buildDetailRow(
                    'Credit Account',
                    _creditAccountName ?? entry.akunCredit.toString(),
                  ),
                  _buildDetailRow(
                    'Credit Amount',
                    creditAmount,
                    isAmount: true,
                  ),
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Entry User', entry.entryUser),
                  _buildDetailRow(
                    'Entry Date',
                    _formatDisplayDate(entry.entryDate),
                  ),
                  SizedBox(height: 5),
                  _buildDetailRow('Last Update User', entry.updateUser),
                  _buildDetailRow(
                    'Last Update Date',
                    _formatDisplayDate(entry.updateDate),
                  ),
                  _buildDetailRow('Flag Aktif', entry.flagAktif),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ================================================================
// END OF VIEW MEMORIAL JOURNAL ENTRY PAGE
// ================================================================

// ================================================================
// VIEW PURCHASE JOURNAL ENTRY PAGE (Using PurchaseJournalDetail)
// ================================================================
class ViewPurchaseJournalEntryPage extends StatefulWidget {
  final int entryId;
  const ViewPurchaseJournalEntryPage({Key? key, required this.entryId})
    : super(key: key);
  @override
  _ViewPurchaseJournalEntryPageState createState() =>
      _ViewPurchaseJournalEntryPageState();
}

class _ViewPurchaseJournalEntryPageState
    extends State<ViewPurchaseJournalEntryPage> {
  PurchaseJournalDetail? _entry; // Use the new Detail model
  // ... (account name state variables remain the same)
  String? _debitAccountName;
  String? _creditAccountName;
  String? _debitAccountDiscName;
  String? _creditAccountDiscName;

  bool _isLoadingData = true;
  String? _fetchError;

  // (Account cache logic remains the same)
  static List<Account> _allAccountsCache = [];
  static bool _accountsCachePopulated = false;
  static bool _isFetchingAccountsGlobal = false;

  @override
  void initState() {
    super.initState();
    _fetchEntryAndAccountDetails();
  }

  Future<void> _fetchAllAccountsIfNeeded() async {
    /* ... same ... */
    if (_accountsCachePopulated || _isFetchingAccountsGlobal) return;
    _isFetchingAccountsGlobal = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Auth token missing for accounts fetch.');
      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 20));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allAccountsCache =
            data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
        _accountsCachePopulated = true;
      } else {
        throw Exception(
          'Failed to load account list. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error fetching global account list: $e");
    } finally {
      _isFetchingAccountsGlobal = false;
    }
  }

  Future<void> _fetchEntryAndAccountDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _fetchError = null;
    });
    try {
      await _fetchAllAccountsIfNeeded();
      if (!mounted) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse(
        '$baseUrl/api/API/ViewJPB?id=${widget.entryId}',
      ); // Correct endpoint
      final headers = {'Authorization': 'Bearer $token'};
      print("Fetching Purchase Journal Detail: $url");
      final response = await http
          .post(url, headers: headers)
          .timeout(Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final fetchedEntry = PurchaseJournalDetail.fromJson(
          data,
        ); // Use new Detail model

        // Account name lookup logic remains the same, using fetchedEntry fields
        String? debitName = "Acc: ${fetchedEntry.akunDebit}";
        String? creditName = "Acc: ${fetchedEntry.akunCredit}";
        String? debitDiscName =
            fetchedEntry.akunDebitDisc != 0
                ? "Acc: ${fetchedEntry.akunDebitDisc}"
                : null;
        String? creditDiscName =
            fetchedEntry.akunCreditDisc != 0
                ? "Acc: ${fetchedEntry.akunCreditDisc}"
                : null;

        if (_accountsCachePopulated) {
          final debitAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunDebit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunDebit,
                  accountName: '(Unknown)',
                ),
          );
          debitName = '${debitAcc.accountName}';
          final creditAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunCredit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunCredit,
                  accountName: '(Unknown)',
                ),
          );
          creditName = '${creditAcc.accountName}';
          if (fetchedEntry.akunDebitDisc != 0) {
            final debitDiscAcc = _allAccountsCache.firstWhere(
              (acc) => acc.accountNo == fetchedEntry.akunDebitDisc,
              orElse:
                  () => Account(
                    accountNo: fetchedEntry.akunDebitDisc,
                    accountName: '(Unknown)',
                  ),
            );
            debitDiscName = '${debitDiscAcc.accountName}';
          }
          if (fetchedEntry.akunCreditDisc != 0) {
            final creditDiscAcc = _allAccountsCache.firstWhere(
              (acc) => acc.accountNo == fetchedEntry.akunCreditDisc,
              orElse:
                  () => Account(
                    accountNo: fetchedEntry.akunCreditDisc,
                    accountName: '(Unknown)',
                  ),
            );
            creditDiscName = '${creditDiscAcc.accountName}';
          }
        }
        if (mounted) {
          setState(() {
            _entry = fetchedEntry;
            _debitAccountName = debitName;
            _creditAccountName = creditName;
            _debitAccountDiscName = debitDiscName;
            _creditAccountDiscName = creditDiscName;
            _isLoadingData = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load purchase entry details. Status: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      print("Error fetching purchase entry details: $e");
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String? value, {bool isAmount = false}) {
    /* ... same ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16),
              textAlign: isAmount ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String? dateString) {
    /* ... same ... */
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      if (dateString.startsWith("0001-01-01")) return 'N/A (Default Date)';
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (e) {
      print("Error parsing date '$dateString': $e");
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      /* ... loading ... */
      return Scaffold(
        appBar: AppBar(title: Text('Loading Purchase...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_fetchError != null || _entry == null) {
      /* ... error ... */
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading details: ${_fetchError ?? "Entry not found."}',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final entry = _entry!;
    final String valueAmount =
        entry.formattedValue; // From PurchaseJournalDetail
    final String valueDiscAmount =
        entry.formattedValueDisc; // From PurchaseJournalDetail

    return Scaffold(
      appBar: AppBar(title: Text('Purchase Detail: ${entry.transNo}')),
      body: RefreshIndicator(
        onRefresh: _fetchEntryAndAccountDetails,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'Purchase Entry Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Transaction No', entry.transNo),
                  _buildDetailRow('Transaction Date', entry.formattedDate),
                  _buildDetailRow('Description', entry.description),
                  Divider(height: 20),
                  _buildDetailRow(
                    'Debit Account',
                    _debitAccountName ?? entry.akunDebit.toString(),
                  ),
                  _buildDetailRow('Value', valueAmount, isAmount: true),
                  SizedBox(height: 10),
                  _buildDetailRow(
                    'Credit Account',
                    _creditAccountName ?? entry.akunCredit.toString(),
                  ),
                  SizedBox(height: 10),
                  if (entry.valueDisc != 0 ||
                      (entry.akunDebitDisc != 0 &&
                          _debitAccountDiscName != null) ||
                      (entry.akunCreditDisc != 0 &&
                          _creditAccountDiscName != null)) ...[
                    Text(
                      'Discount Details:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    _buildDetailRow(
                      'Debit Disc Acc',
                      _debitAccountDiscName ??
                          (entry.akunDebitDisc != 0
                              ? entry.akunDebitDisc.toString()
                              : 'N/A'),
                    ),
                    _buildDetailRow(
                      'Value Discount',
                      valueDiscAmount,
                      isAmount: true,
                    ),
                    SizedBox(height: 10),
                    _buildDetailRow(
                      'Credit Disc Acc',
                      _creditAccountDiscName ??
                          (entry.akunCreditDisc != 0
                              ? entry.akunCreditDisc.toString()
                              : 'N/A'),
                    ),
                  ],
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Entry User', entry.entryUser),
                  _buildDetailRow(
                    'Entry Date',
                    _formatDisplayDate(entry.entryDate),
                  ),
                  SizedBox(height: 5),
                  _buildDetailRow('Last Update User', entry.updateUser),
                  _buildDetailRow(
                    'Last Update Date',
                    _formatDisplayDate(entry.updateDate),
                  ),
                  _buildDetailRow('Flag Aktif', entry.flagAktif),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// END OF VIEW PURCHASE JOURNAL ENTRY PAGE
// ================================================================
// ================================================================
// VIEW SALES JOURNAL ENTRY PAGE (Using SalesJournalDetail)
// ================================================================
class ViewSalesJournalEntryPage extends StatefulWidget {
  final int entryId;
  const ViewSalesJournalEntryPage({Key? key, required this.entryId})
    : super(key: key);
  @override
  _ViewSalesJournalEntryPageState createState() =>
      _ViewSalesJournalEntryPageState();
}

class _ViewSalesJournalEntryPageState extends State<ViewSalesJournalEntryPage> {
  SalesJournalDetail? _entry; // Use the new Detail model
  // ... (account name state variables remain the same)
  String? _debitAccountName;
  String? _creditAccountName;
  String? _debitAccountDiscName;
  String? _creditAccountDiscName;

  bool _isLoadingData = true;
  String? _fetchError;

  // (Account cache logic remains the same)
  static List<Account> _allAccountsCache = [];
  static bool _accountsCachePopulated = false;
  static bool _isFetchingAccountsGlobal = false;

  @override
  void initState() {
    super.initState();
    _fetchEntryAndAccountDetails();
  }

  Future<void> _fetchAllAccountsIfNeeded() async {
    /* ... same ... */
    if (_accountsCachePopulated || _isFetchingAccountsGlobal) return;
    _isFetchingAccountsGlobal = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Auth token missing for accounts fetch.');
      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 20));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allAccountsCache =
            data.map((jsonItem) => Account.fromJson(jsonItem)).toList();
        _accountsCachePopulated = true;
      } else {
        throw Exception(
          'Failed to load account list. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error fetching global account list: $e");
    } finally {
      _isFetchingAccountsGlobal = false;
    }
  }

  Future<void> _fetchEntryAndAccountDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _fetchError = null;
    });
    try {
      await _fetchAllAccountsIfNeeded();
      if (!mounted) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse(
        '$baseUrl/api/API/ViewJPN?id=${widget.entryId}',
      ); // Correct endpoint for Sales
      final headers = {'Authorization': 'Bearer $token'};
      print("Fetching Sales Journal Detail: $url");
      final response = await http
          .post(url, headers: headers)
          .timeout(Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final fetchedEntry = SalesJournalDetail.fromJson(
          data,
        ); // Use new Detail model

        // Account name lookup logic remains the same, using fetchedEntry fields
        String? debitName = "Acc: ${fetchedEntry.akunDebit}";
        String? creditName = "Acc: ${fetchedEntry.akunCredit}";
        String? debitDiscName =
            fetchedEntry.akunDebitDisc != 0
                ? "Acc: ${fetchedEntry.akunDebitDisc}"
                : null;
        String? creditDiscName =
            fetchedEntry.akunCreditDisc != 0
                ? "Acc: ${fetchedEntry.akunCreditDisc}"
                : null;

        if (_accountsCachePopulated) {
          final debitAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunDebit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunDebit,
                  accountName: '(Unknown)',
                ),
          );
          debitName = '${debitAcc.accountName}';
          final creditAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunCredit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunCredit,
                  accountName: '(Unknown)',
                ),
          );
          creditName = '${creditAcc.accountName}';
          if (fetchedEntry.akunDebitDisc != 0) {
            final debitDiscAcc = _allAccountsCache.firstWhere(
              (acc) => acc.accountNo == fetchedEntry.akunDebitDisc,
              orElse:
                  () => Account(
                    accountNo: fetchedEntry.akunDebitDisc,
                    accountName: '(Unknown)',
                  ),
            );
            debitDiscName = '${debitDiscAcc.accountName}';
          }
          if (fetchedEntry.akunCreditDisc != 0) {
            final creditDiscAcc = _allAccountsCache.firstWhere(
              (acc) => acc.accountNo == fetchedEntry.akunCreditDisc,
              orElse:
                  () => Account(
                    accountNo: fetchedEntry.akunCreditDisc,
                    accountName: '(Unknown)',
                  ),
            );
            creditDiscName = '${creditDiscAcc.accountName}';
          }
        }
        if (mounted) {
          setState(() {
            _entry = fetchedEntry;
            _debitAccountName = debitName;
            _creditAccountName = creditName;
            _debitAccountDiscName = debitDiscName;
            _creditAccountDiscName = creditDiscName;
            _isLoadingData = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load sales entry details. Status: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      print("Error fetching sales entry details: $e");
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String? value, {bool isAmount = false}) {
    /* ... same ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16),
              textAlign: isAmount ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String? dateString) {
    /* ... same ... */
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      if (dateString.startsWith("0001-01-01")) return 'N/A (Default Date)';
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (e) {
      print("Error parsing date '$dateString': $e");
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      /* ... loading ... */
      return Scaffold(
        appBar: AppBar(title: Text('Loading Sales...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_fetchError != null || _entry == null) {
      /* ... error ... */
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading details: ${_fetchError ?? "Entry not found."}',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final entry = _entry!;
    // --- Use formattedValue and formattedValueDisc from SalesJournalDetail ---
    final String valueAmount = entry.formattedValue;
    final String valueDiscAmount = entry.formattedValueDisc;
    // ----------------------------------------------------------------------

    return Scaffold(
      appBar: AppBar(title: Text('Sales Detail: ${entry.transNo}')),
      body: RefreshIndicator(
        onRefresh: _fetchEntryAndAccountDetails,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'Sales Entry Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Transaction No', entry.transNo),
                  _buildDetailRow('Transaction Date', entry.formattedDate),
                  _buildDetailRow('Description', entry.description),
                  Divider(height: 20),
                  _buildDetailRow(
                    'Debit Account',
                    _debitAccountName ?? entry.akunDebit.toString(),
                  ),
                  _buildDetailRow(
                    'Sales Value (Debit)',
                    valueAmount,
                    isAmount: true,
                  ), // Typically DR A/R or Cash
                  SizedBox(height: 10),
                  _buildDetailRow(
                    'Credit Account',
                    _creditAccountName ?? entry.akunCredit.toString(),
                  ),
                  _buildDetailRow(
                    'Sales Revenue (Credit)',
                    valueAmount,
                    isAmount: true,
                  ), // Typically CR Sales Revenue
                  SizedBox(height: 10),
                  if (entry.valueDisc != 0 ||
                      (entry.akunDebitDisc != 0 &&
                          _debitAccountDiscName != null) ||
                      (entry.akunCreditDisc != 0 &&
                          _creditAccountDiscName != null)) ...[
                    Text(
                      'Discount Details:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    _buildDetailRow(
                      'Debit Disc Acc',
                      _debitAccountDiscName ??
                          (entry.akunDebitDisc != 0
                              ? entry.akunDebitDisc.toString()
                              : 'N/A'),
                    ),
                    _buildDetailRow(
                      'Sales Discount (Debit)',
                      valueDiscAmount,
                      isAmount: true,
                    ),
                    SizedBox(height: 10),
                    _buildDetailRow(
                      'Credit Disc Acc',
                      _creditAccountDiscName ??
                          (entry.akunCreditDisc != 0
                              ? entry.akunCreditDisc.toString()
                              : 'N/A'),
                    ),
                  ],
                  Divider(height: 30, thickness: 1),
                  _buildDetailRow('Entry User', entry.entryUser),
                  _buildDetailRow(
                    'Entry Date',
                    _formatDisplayDate(entry.entryDate),
                  ),
                  SizedBox(height: 5),
                  _buildDetailRow('Last Update User', entry.updateUser),
                  _buildDetailRow(
                    'Last Update Date',
                    _formatDisplayDate(entry.updateDate),
                  ),
                  _buildDetailRow('Flag Aktif', entry.flagAktif),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ================================================================
// END OF VIEW SALES JOURNAL ENTRY PAGE
// ================================================================

// ================================================================
// ACCOUNT SETTINGS PAGE
// ================================================================

// --- Placeholder Pages for Add/Edit/View Account Settings ---
// ================================================================
// ADD ACCOUNT SETTING PAGE
// ================================================================
class AddAccountSettingPage extends StatefulWidget {
  @override
  _AddAccountSettingPageState createState() => _AddAccountSettingPageState();
}

class _AddAccountSettingPageState extends State<AddAccountSettingPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNoController = TextEditingController();
  final _accountNameController = TextEditingController();

  // Dropdown values
  String? _selectedHierarchy; // Can be "HDR" or "DTL"
  String? _selectedAkunDK; // Can be "D" or "K"
  String? _selectedAkunNRLR; // Can be "NR" or "LR"

  bool _isSubmitting = false;
  String? _submitError;

  // Define dropdown items - consider making these constants or enums for better type safety
  final List<String> _hierarchyOptions = ['hdr', 'dtl'];
  final List<String> _akunDKOptions = ['D', 'K'];
  final List<String> _akunNRLROptions = ['NR', 'LR'];

  @override
  void dispose() {
    _accountNoController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submitNewAccount() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if validation fails
    }
    // Additional checks for dropdowns
    if (_selectedHierarchy == null ||
        _selectedAkunDK == null ||
        _selectedAkunNRLR == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select all dropdown values.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      // --- Prepare data for API ---
      final int? accountNo = int.tryParse(_accountNoController.text);
      if (accountNo == null) throw Exception('Invalid Account Number.');

      final body = json.encode({
        "account_no": accountNo,
        "hierarchy": _selectedHierarchy,
        "account_name": _accountNameController.text.trim(),
        "akundk": _selectedAkunDK,
        "akunnrlr": _selectedAkunNRLR,
        // Add other default fields if your API requires them for new accounts
        // e.g., "company_id": "YOUR_DEFAULT_COMPANY_ID_IF_NEEDED",
        // "flag_aktif": "1", // Default to active
      });

      // --- REPLACE WITH YOUR ACTUAL "ADD ACCOUNT" API ENDPOINT ---
      final url = Uri.parse(
        '$baseUrl/api/API/CreateAccount',
      ); // Example endpoint
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      print("Submitting New Account: $body");
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 201 Created
        print("Add Account Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Pop and signal success to refresh previous page
      } else {
        String serverMessage = response.reasonPhrase ?? 'Submission Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Add Account Failed Body: ${response.body}");
        throw Exception(
          'Failed to add account. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _submitError = "Submission request timed out.";
    } on http.ClientException catch (e) {
      _submitError = "Network error during submission: ${e.message}.";
    } catch (e) {
      print("Error submitting new account: $e");
      _submitError = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Account Number Input ---
              TextFormField(
                controller: _accountNoController,
                decoration: InputDecoration(
                  labelText: 'Account Number*',
                  border: OutlineInputBorder(),
                  hintText: 'Enter account number (e.g., 1100001)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account number.';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number.';
                  }
                  // Add more specific validation if needed (e.g., length, range)
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Account Name Input ---
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Name*',
                  border: OutlineInputBorder(),
                  hintText: 'Enter account name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Hierarchy Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedHierarchy,
                decoration: InputDecoration(
                  labelText: 'Hierarchy*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select Hierarchy (HDR/DTL)'),
                isExpanded: true,
                items:
                    _hierarchyOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHierarchy = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please select hierarchy.' : null,
              ),
              SizedBox(height: 16),

              // --- Akun D/K Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAkunDK,
                decoration: InputDecoration(
                  labelText: 'Normal Balance (D/K)*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select D or K'),
                isExpanded: true,
                items:
                    _akunDKOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value == 'D' ? 'D - Debit' : 'K - Kredit'),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAkunDK = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select D or K.' : null,
              ),
              SizedBox(height: 16),

              // --- Akun NR/LR Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAkunNRLR,
                decoration: InputDecoration(
                  labelText: 'Account Type (NR/LR)*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select NR or LR'),
                isExpanded: true,
                items:
                    _akunNRLROptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'NR'
                              ? 'NR - Neraca (Balance Sheet)'
                              : 'LR - Laba Rugi (Income St.)',
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAkunNRLR = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select NR or LR.' : null,
              ),
              SizedBox(height: 30),

              // --- Submission Error Message ---
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // --- Submit Button ---
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Add Account'),
                    onPressed: _submitNewAccount,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
// ================================================================
// END OF ADD ACCOUNT SETTING PAGE
// ================================================================

// ================================================================
// EDIT ACCOUNT SETTING PAGE
// ================================================================
class EditAccountSettingPage extends StatefulWidget {
  final AccountSettingEntry account; // Account to be edited

  const EditAccountSettingPage({Key? key, required this.account})
    : super(key: key);

  @override
  _EditAccountSettingPageState createState() => _EditAccountSettingPageState();
}

class _EditAccountSettingPageState extends State<EditAccountSettingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNoController;
  late TextEditingController _accountNameController;

  // Dropdown values
  String? _selectedHierarchy;
  String? _selectedAkunDK;
  String? _selectedAkunNRLR;
  String? _selectedFlagAktif; // For active/inactive status

  bool _isSubmitting = false;
  String? _submitError;

  final List<String> _hierarchyOptions = ['HDR', 'DTL'];
  final List<String> _akunDKOptions = ['D', 'K'];
  final List<String> _akunNRLROptions = ['NR', 'LR'];
  final List<Map<String, String>> _statusOptions = [
    // For flag_aktif
    {'value': '1', 'display': 'Active'},
    {'value': '0', 'display': 'Inactive'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers and dropdowns with existing account data
    _accountNoController = TextEditingController(
      text: widget.account.accountNo.toString(),
    );
    _accountNameController = TextEditingController(
      text: widget.account.accountName,
    );
    _selectedHierarchy = widget.account.hierarchy;
    _selectedAkunDK = widget.account.akunDK;
    _selectedAkunNRLR = widget.account.akunNRLR;
    _selectedFlagAktif = widget.account.flagAktif;

    // Ensure selected values are part of the options
    if (!_hierarchyOptions.contains(_selectedHierarchy))
      _selectedHierarchy = null;
    if (!_akunDKOptions.contains(_selectedAkunDK)) _selectedAkunDK = null;
    if (!_akunNRLROptions.contains(_selectedAkunNRLR)) _selectedAkunNRLR = null;
    if (_statusOptions.indexWhere(
          (opt) => opt['value'] == _selectedFlagAktif,
        ) ==
        -1)
      _selectedFlagAktif = null;
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHierarchy == null ||
        _selectedAkunDK == null ||
        _selectedAkunNRLR == null ||
        _selectedFlagAktif == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select all dropdown values.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final int? accountNo = int.tryParse(_accountNoController.text);
      if (accountNo == null) throw Exception('Invalid Account Number.');

      final body = json.encode({
        "id": widget.account.id, // Include the ID for update
        "account_no": accountNo,
        "hierarchy": _selectedHierarchy,
        "account_name": _accountNameController.text.trim(),
        "akundk": _selectedAkunDK,
        "akunnrlr": _selectedAkunNRLR,
        "flag_aktif": _selectedFlagAktif,
        "company_id":
            widget
                .account
                .companyId, // Send back company_id if needed for update
        // "entry_user": widget.account.entryUser, // Usually not updated
        // "entry_date": widget.account.entryDate?.toIso8601String(), // Usually not updated
        // "update_user": "CURRENT_LOGGED_IN_USER", // API should handle this or pass if required
      });

      // --- REPLACE WITH YOUR ACTUAL "UPDATE ACCOUNT" API ENDPOINT ---
      // It might be a PUT request or POST, often includes ID in path or body
      final url = Uri.parse(
        '$baseUrl/api/Admin/UpdateAccount/${widget.account.id}',
      ); // Example: PUT /api/Admin/UpdateAccount/{id}
      // OR: final url = Uri.parse('$baseUrl/api/Admin/UpdateAccount'); // If ID is only in body

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      print("Updating Account ${widget.account.id}: $body");

      // Use http.put or http.post based on your API design
      final response = await http
          .put(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));
      // final response = await http.post(url, headers: headers, body: body).timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content for successful PUT
        print("Update Account Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Pop and signal success to refresh previous page
      } else {
        String serverMessage = response.reasonPhrase ?? 'Update Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {
          /* Ignore */
        }
        print("Update Account Failed Body: ${response.body}");
        throw Exception(
          'Failed to update account. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } on TimeoutException {
      _submitError = "Update request timed out.";
    } on http.ClientException catch (e) {
      _submitError = "Network error during update: ${e.message}.";
    } catch (e) {
      print("Error updating account: $e");
      _submitError = "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Account: ${widget.account.accountNo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Account Number (Potentially Read-only or validated for uniqueness if changed) ---
              TextFormField(
                controller: _accountNoController,
                decoration: InputDecoration(
                  labelText: 'Account Number*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // readOnly: true, // Consider if account_no should be editable. If so, API needs to handle potential conflicts.
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter an account number.';
                  if (int.tryParse(value.trim()) == null)
                    return 'Please enter a valid number.';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Account Name Input ---
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Name*',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter an account name.';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // --- Hierarchy Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedHierarchy,
                decoration: InputDecoration(
                  labelText: 'Hierarchy*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select Hierarchy (HDR/DTL)'),
                isExpanded: true,
                items:
                    _hierarchyOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHierarchy = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please select hierarchy.' : null,
              ),
              SizedBox(height: 16),

              // --- Akun D/K Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAkunDK,
                decoration: InputDecoration(
                  labelText: 'Normal Balance (D/K)*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select D or K'),
                isExpanded: true,
                items:
                    _akunDKOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value == 'D' ? 'D - Debit' : 'K - Kredit'),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAkunDK = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select D or K.' : null,
              ),
              SizedBox(height: 16),

              // --- Akun NR/LR Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedAkunNRLR,
                decoration: InputDecoration(
                  labelText: 'Account Type (NR/LR)*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select NR or LR'),
                isExpanded: true,
                items:
                    _akunNRLROptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'NR'
                              ? 'NR - Neraca (Balance Sheet)'
                              : 'LR - Laba Rugi (Income St.)',
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAkunNRLR = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select NR or LR.' : null,
              ),
              SizedBox(height: 16),

              // --- Flag Aktif Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedFlagAktif,
                decoration: InputDecoration(
                  labelText: 'Status*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                ),
                hint: Text('Select Status'),
                isExpanded: true,
                items:
                    _statusOptions.map((Map<String, String> option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['display']!),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFlagAktif = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select a status.' : null,
              ),
              SizedBox(height: 30),

              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.save_alt),
                    label: Text('Update Account'),
                    onPressed: _updateAccount,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
// ================================================================
// END OF EDIT ACCOUNT SETTING PAGE
// ================================================================

class ViewAccountSettingPage extends StatelessWidget {
  // For viewing details (optional, could be combined with edit)
  final AccountSettingEntry account;
  const ViewAccountSettingPage({Key? key, required this.account})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Account: ${account.accountNo}')),
      body: Center(child: Text('Details for Account ID: ${account.id}')),
    );
  }
}
// ------------------------------------------------------------

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  List<AccountSettingEntry> _allFetchedAccounts = []; // MASTER LIST from API
  List<AccountSettingEntry> _displayedAccounts =
      []; // UI LIST (subset of master)

  bool _isLoadingApi = false; // True when fetching ALL data from API
  String? _error;

  // Client-side pagination state
  int _currentlyDisplayedItemsCount = 0;
  final int _pageSizeClient = 15; // How many items to show per "page" on client
  bool _canLoadMoreClient = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeSearchQuery = '';

  int _sortColumnIndex = 1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    print("ACC_SETTINGS_CLIENT_SIDE: initState");
    _fetchDataFromApiAndInitializeDisplay(); // Initial fetch of ALL data
    _searchController.addListener(_onSearchChangedWithDebounce);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChangedWithDebounce);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChangedWithDebounce() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final newSearchQuery = _searchController.text.trim();
      print(
        "ACC_SETTINGS_CLIENT_SIDE: Debounce. Current: '$_activeSearchQuery', New: '$newSearchQuery'",
      );
      if (_activeSearchQuery != newSearchQuery) {
        _activeSearchQuery = newSearchQuery;
        _fetchDataFromApiAndInitializeDisplay(); // New search re-fetches ALL data
      }
    });
  }

  // Fetches ALL data from the API based on search query (no server-side page parameter)
  Future<void> _fetchDataFromApiAndInitializeDisplay() async {
    if (!mounted) {
      print("ACC_SETTINGS_CLIENT_SIDE: _fetchData - NOT MOUNTED");
      return;
    }
    if (_isLoadingApi) {
      print("ACC_SETTINGS_CLIENT_SIDE: _fetchData - ALREADY LOADING API");
      return;
    }

    print(
      "ACC_SETTINGS_CLIENT_SIDE: _fetchData - Setting _isLoadingApi=true. Search: '$_activeSearchQuery'",
    );
    setState(() {
      _isLoadingApi = true;
      _error = null;
      _allFetchedAccounts.clear();
      _displayedAccounts.clear();
      _currentlyDisplayedItemsCount = 0;
      _canLoadMoreClient = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      var queryParams = {
        // NO 'page' or 'pageSize' here, assuming API returns all for search
        if (_activeSearchQuery.isNotEmpty) 'search': _activeSearchQuery,
      };
      final url = Uri.parse(
        '$baseUrl/api/API/getdataAccount',
      ) // YOUR ACCOUNTS LIST API
      .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      print("ACC_SETTINGS_CLIENT_SIDE: Fetching ALL API Data: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) {
        print(
          "ACC_SETTINGS_CLIENT_SIDE: _fetchData - NOT MOUNTED after API call.",
        );
        return;
      }

      if (response.statusCode == 200) {
        print("ACC_SETTINGS_CLIENT_SIDE: API success (200)");
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        // Store all fetched entries
        _allFetchedAccounts =
            data
                .map((jsonItem) => AccountSettingEntry.fromJson(jsonItem))
                .toList();
        print(
          "ACC_SETTINGS_CLIENT_SIDE: Fetched ${_allFetchedAccounts.length} total entries.",
        );

        _applySortToAllFetched(); // Sort the entire fetched list once
        _showNextClientPage(
          isInitialLoad: true,
        ); // Display the first "page" of data
      } else {
        print("ACC_SETTINGS_CLIENT_SIDE: API error: ${response.statusCode}");
        throw Exception(
          'Failed to load accounts. Status: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print("ACC_SETTINGS_CLIENT_SIDE: EXCEPTION in _fetchData: $e\n$s");
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
        });
        print(
          "ACC_SETTINGS_CLIENT_SIDE: _fetchData - FINALLY. _isLoadingApi: $_isLoadingApi, _error: $_error",
        );
      }
    }
  }

  void _applySortToAllFetched() {
    if (!mounted || _allFetchedAccounts.isEmpty) return;
    print(
      "ACC_SETTINGS_CLIENT_SIDE: Sorting ${_allFetchedAccounts.length} total items.",
    );
    _allFetchedAccounts.sort((a, b) {
      /* ... sort logic ... */
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = (a.id).compareTo(b.id);
          break;
        case 1:
          compareResult = (a.accountNo).compareTo(b.accountNo);
          break;
        case 2:
          compareResult = a.accountName.toLowerCase().compareTo(
            b.accountName.toLowerCase(),
          );
          break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    print(
      "ACC_SETTINGS_CLIENT_SIDE: _onSort - Column: $columnIndex, Ascending: $ascending",
    );
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySortToAllFetched(); // Sort the master list
      // Reset and show the first page of the newly sorted data
      _displayedAccounts.clear();
      _currentlyDisplayedItemsCount = 0;
      _showNextClientPage(isInitialLoad: true);
    });
  }

  // This function handles displaying the next "page" from _allFetchedAccounts
  void _showNextClientPage({bool isInitialLoad = false}) {
    if (!mounted) return;
    print(
      "ACC_SETTINGS_CLIENT_SIDE: _showNextClientPage. Initial: $isInitialLoad. Current displayed: $_currentlyDisplayedItemsCount / Total fetched: ${_allFetchedAccounts.length}",
    );

    if (isInitialLoad) {
      _displayedAccounts.clear();
      _currentlyDisplayedItemsCount = 0;
    }

    if (_currentlyDisplayedItemsCount >= _allFetchedAccounts.length) {
      print("ACC_SETTINGS_CLIENT_SIDE: All items already displayed.");
      setState(() {
        _canLoadMoreClient = false;
      });
      return;
    }

    int end = _currentlyDisplayedItemsCount + _pageSizeClient;
    if (end > _allFetchedAccounts.length) {
      end = _allFetchedAccounts.length;
    }

    // Add the next chunk of data to be displayed
    // No, we replace _displayedAccounts with the current view window
    // _displayedAccounts.addAll(_allFetchedAccounts.sublist(_currentlyDisplayedItemsCount, end));

    setState(() {
      // _displayedAccounts is a "window" into _allFetchedAccounts
      _displayedAccounts = _allFetchedAccounts.sublist(0, end);
      _currentlyDisplayedItemsCount = end;
      _canLoadMoreClient =
          _currentlyDisplayedItemsCount < _allFetchedAccounts.length;
      print(
        "ACC_SETTINGS_CLIENT_SIDE: Now displaying ${_displayedAccounts.length}. Can load more: $_canLoadMoreClient",
      );
    });
  }

  // Action Handlers (call _fetchDataAndInitializeDisplay on success)
  void _viewAccount(AccountSettingEntry account) {
    /* ... */
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAccountSettingPage(account: account),
      ),
    );
  }

  void _editAccount(AccountSettingEntry account) async {
    /* ... */
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountSettingPage(account: account),
      ),
    );
    if (result == true && mounted) {
      _fetchDataFromApiAndInitializeDisplay();
    }
  }

  void _deleteAccount(AccountSettingEntry account) async {
    /* ... delete logic, calls _fetchDataAndInitializeDisplay on success ... */
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete account "${account.accountName}" (${account.accountNo})?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _isLoadingApi = true;
      });
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('auth_token');
        if (token == null || token.isEmpty)
          throw Exception('Authentication required.');
        final url = Uri.parse('$baseUrl/api/Admin/DeleteAccount/${account.id}');
        final headers = {'Authorization': 'Bearer $token'};
        print("Deleting Account: $url");
        final response = await http
            .delete(url, headers: headers)
            .timeout(Duration(seconds: 30));
        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchDataFromApiAndInitializeDisplay();
        } else {
          throw Exception(
            'Failed to delete account. Status: ${response.statusCode}\nBody: ${response.body}',
          );
        }
      } catch (e) {
        print("Error deleting account: $e");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
      } finally {
        if (mounted)
          setState(() {
            _isLoadingApi = false;
          });
      }
    }
  }

  void _navigateToAddAccountPage() async {
    /* ... */
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAccountSettingPage()),
    );
    if (result == true && mounted) {
      _fetchDataFromApiAndInitializeDisplay();
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "ACC_SETTINGS_CLIENT_SIDE: build - _isLoadingApi: $_isLoadingApi, _displayedAccounts.length: ${_displayedAccounts.length}, _error: $_error",
    );
    return Scaffold(
      appBar: AppBar(title: Text('Account Settings (Client)')),
      body: Column(
        children: [
          Padding(
            /* ... Search TextField ... */ padding: const EdgeInsets.fromLTRB(
              12.0,
              12.0,
              12.0,
              8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Account No. or Name',
                hintText: 'Enter search term...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _activeSearchQuery = '';
                            _fetchDataFromApiAndInitializeDisplay();
                          },
                        )
                        : null,
              ),
            ),
          ),
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAccountPage,
        tooltip: 'Add New Account',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDataArea() {
    print(
      "ACC_SETTINGS_CLIENT_SIDE: _buildDataArea - _isLoadingApi: $_isLoadingApi, _displayedAccounts.length: ${_displayedAccounts.length}, _error: $_error",
    );
    if (_isLoadingApi && _allFetchedAccounts.isEmpty) {
      // Show full screen loader only if completely initial fetch
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorWidget(_error!),
        ),
      );
    }
    if (_displayedAccounts.isEmpty && !_isLoadingApi) {
      // After loading, if still no data to display
      return Center(
        child: Text(
          _activeSearchQuery.isNotEmpty
              ? 'No accounts found for "$_activeSearchQuery".'
              : 'No accounts to display. Tap + to add.',
        ),
      );
    }

    // DataTable is now inside a Column with Load More button, all wrapped in SingleChildScrollView
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDataTable(), // Renders _displayedAccounts
          _buildPaginationControlsClientSide(),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    /* ... DataTable definition using _displayedAccounts ... */
    final List<DataColumn> columns = [
      DataColumn(
        label: Text('ID'),
        tooltip: 'Internal ID',
        numeric: true,
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Acc. No'),
        tooltip: 'Account Number',
        numeric: true,
        onSort: _onSort,
      ),
      DataColumn(
        label: Text('Account Name'),
        tooltip: 'Account Name/Description',
        onSort: _onSort,
      ),
      DataColumn(label: Text('Actions')),
    ];
    final List<DataRow> rows =
        _displayedAccounts.map((account) {
          return DataRow(
            cells: [
              DataCell(Text(account.id.toString())),
              DataCell(Text(account.accountNo.toString())),
              DataCell(Text(account.accountName)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                      tooltip: 'Edit',
                      onPressed: () => _editAccount(account),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _deleteAccount(account),
                    ),
                  ],
                ),
              ),
            ],
            onSelectChanged: (selected) {
              if (selected ?? false) _viewAccount(account);
            },
          );
        }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        showCheckboxColumn: true,
        columnSpacing: 15,
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
        ),
        headingRowColor: MaterialStateProperty.resolveWith<Color?>(
          (_) => Colors.blueGrey[50],
        ),
      ),
    );
  }

  Widget _buildPaginationControlsClientSide() {
    print(
      "ACC_SETTINGS_CLIENT_SIDE: _buildPaginationControls - _isLoadingApi: $_isLoadingApi, _canLoadMoreClient: $_canLoadMoreClient, displayed: ${_displayedAccounts.length}, allFetched: ${_allFetchedAccounts.length}",
    );

    if (_isLoadingApi && _allFetchedAccounts.isNotEmpty) {
      // Show spinner at bottom if loading API for search but some data (old search) is there
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_canLoadMoreClient && !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: () => _showNextClientPage(),
            child: Text(
              'Load More (${_allFetchedAccounts.length - _currentlyDisplayedItemsCount} remaining)',
            ),
          ),
        ),
      );
    } else if (_allFetchedAccounts.isNotEmpty &&
        !_canLoadMoreClient &&
        !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("End of list", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox.shrink(); // If no data or still initial loading
  }

  Widget _buildErrorWidget(String errorMessage) {
    /* ... Error widget ... */
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
            SizedBox(height: 15),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed: () => _fetchDataFromApiAndInitializeDisplay(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ================================================================
// END OF ACCOUNT SETTINGS PAGE
// ================================================================