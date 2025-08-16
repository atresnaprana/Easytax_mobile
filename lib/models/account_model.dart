import 'package:intl/intl.dart';

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
