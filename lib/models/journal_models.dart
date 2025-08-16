import 'package:intl/intl.dart';
import 'account_model.dart';

// --- MEMORIAL JOURNAL ---
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
  final String debitStr;
  final String creditStr;
  final String transDateStr;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

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
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
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
      transDateStr: json['transDateStr'] ?? '',
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedDebit => debitStr;
  String get formattedCredit => creditStr;
}

class MemorialJournalDetail {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final double debit;
  final double credit;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final DateTime? updateDate;
  final DateTime? entryDate;
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
    this.debitAccountName = '',
    this.creditAccountName = '',
  });

  factory MemorialJournalDetail.fromJson(Map<String, dynamic> json) {
    double parseNumeric(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
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
      debit: parseNumeric(json['debit']),
      credit: parseNumeric(json['credit']),
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      updateDate: DateTime.tryParse(json['update_date'] ?? ''),
      entryDate: DateTime.tryParse(json['entry_date'] ?? ''),
    );
  }

  String get formattedDateDisplay =>
      DateFormat('dd MMM yyyy').format(transDate);
  String get formattedDebitValue =>
      NumberFormat.decimalPattern('id').format(debit);
  String get formattedCreditValue =>
      NumberFormat.decimalPattern('id').format(credit);
  String get formattedEntryDate =>
      entryDate != null
          ? DateFormat('dd MMM yyyy, HH:mm').format(entryDate!)
          : 'N/A';
  String get formattedUpdateDate =>
      updateDate != null
          ? DateFormat('dd MMM yyyy, HH:mm').format(updateDate!)
          : 'N/A';
}

// --- PURCHASE JOURNAL ---
class PurchaseJournalEntry {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int akunDebitdisc;
  final int akunCreditdisc;
  final double Value;
  final double ValueDisc;
  final String ValueStr;
  final String ValueStrdisc;
  final String transDateStr;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

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
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
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

    return PurchaseJournalEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunDebitdisc: json['akun_Debitdisc'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      akunCreditdisc: json['akun_Creditdisc'] ?? 0,
      Value: parseDouble(json['value']),
      ValueDisc: parseDouble(json['value_Disc']),
      ValueStr: json['valueStr'] ?? '0,00',
      ValueStrdisc: json['valueDiscStr'] ?? '0,00',
      transDateStr: json['transDateStr'] ?? '',
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => ValueStr;
  String get formattedValueDisc => ValueStrdisc;
}

class PurchaseJournalDetail {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int akunDebitDisc;
  final int akunCreditDisc;
  final double value;
  final double valueDisc;
  final String valueStr;
  final String valueDiscStr;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

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
      akunDebitDisc: json['akun_Debit_disc'] ?? 0,
      akunCreditDisc: json['akun_Credit_disc'] ?? 0,
      value: parseDouble(json['value']),
      valueDisc: parseDouble(json['value_Disc']),
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

// --- SALES JOURNAL ---
class SalesJournalEntry {
  final int id;
  final String companyId;
  final DateTime transDate;
  final String transNo;
  final String description;
  final int akunDebit;
  final int akunCredit;
  final int akunDebitdisc;
  final int akunCreditdisc;
  final double Value;
  final double ValueDisc;
  final String ValueStr;
  final String ValueStrdisc;
  final String transDateStr;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

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
    this.entryUser,
    this.updateUser,
    this.flagAktif,
    this.entryDate,
    this.updateDate,
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

    return SalesJournalEntry(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? '',
      transDate: DateTime.tryParse(json['transDate'] ?? '') ?? DateTime(1970),
      transNo: json['trans_no'] ?? 'N/A',
      description: json['description'] ?? 'No Description',
      akunDebit: json['akun_Debit'] ?? 0,
      akunDebitdisc: json['akun_Debitdisc'] ?? 0,
      akunCredit: json['akun_Credit'] ?? 0,
      akunCreditdisc: json['akun_Creditdisc'] ?? 0,
      Value: parseDouble(json['value']),
      ValueDisc: parseDouble(json['value_Disc']),
      ValueStr: json['valueStr'] ?? '0,00',
      ValueStrdisc: json['valueDiscStr'] ?? '0,00',
      transDateStr: json['transDateStr'] ?? '',
      entryUser: json['entry_user'],
      updateUser: json['update_user'],
      flagAktif: json['flag_aktif'],
      entryDate: json['entry_date'],
      updateDate: json['update_date'],
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);
  String get formattedValue => ValueStr;
  String get formattedValueDisc => ValueStrdisc;
}

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
  final double value;
  final double valueDisc;
  final String valueStr;
  final String valueDiscStr;
  final String? entryUser;
  final String? updateUser;
  final String? flagAktif;
  final String? entryDate;
  final String? updateDate;

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
      value: parseDouble(json['value']),
      valueDisc: parseDouble(json['value_Disc']),
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
