import 'package:intl/intl.dart';

class UserEntry {
  final int id;
  final String? companyId;
  final String customerName; // CUST_NAME
  final String? company;
  final String? npwp;
  final String? address;
  final String? city;
  final String? province;
  final String? postal;
  final DateTime? registerDate; // REG_DATE
  final String? blockFlag; // BL_FLAG
  final DateTime? entryDate; // ENTRY_DATE
  final DateTime? updateDate; // UPDATE_DATE
  final String? entryUser;
  final String? updateUser;
  final String? activeFlag; // FLAG_AKTIF
  final String email; // Email
  final String? ktp;
  final String phone1; // PHONE1
  final String? phone2;
  final String? isApproved; // isApproved
  final String? va1;
  final String?
  va1Note; // Corresponds to "pkg" in the outer JSON? Or specific note
  final int? totalStoreConfig;
  final bool? isBlackList;

  // Fields for Add/Edit (not always present in list view JSON)
  final String? password;
  final String? confirmPassword;

  UserEntry({
    required this.id,
    this.companyId,
    required this.customerName,
    this.company,
    this.npwp,
    this.address,
    this.city,
    this.province,
    this.postal,
    this.registerDate,
    this.blockFlag,
    this.entryDate,
    this.updateDate,
    this.entryUser,
    this.updateUser,
    this.activeFlag,
    required this.email,
    this.ktp,
    required this.phone1,
    this.phone2,
    this.isApproved,
    this.va1,
    this.va1Note,
    this.totalStoreConfig,
    this.isBlackList,
    this.password, // For add/edit
    this.confirmPassword, // For add/edit
  });

  factory UserEntry.fromJson(Map<String, dynamic> json) {
    return UserEntry(
      id: json['id'] ?? 0,
      companyId: json['companY_ID'], // Note casing from your JSON
      customerName: json['cusT_NAME'] ?? 'N/A', // Note casing
      company: json['company'],
      npwp: json['npwp'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      postal: json['postal'],
      registerDate:
          json['reG_DATE'] != null ? DateTime.tryParse(json['reG_DATE']) : null,
      blockFlag: json['bL_FLAG'],
      entryDate:
          json['entrY_DATE'] != null
              ? DateTime.tryParse(json['entrY_DATE'])
              : null,
      updateDate:
          json['updatE_DATE'] != null
              ? DateTime.tryParse(json['updatE_DATE'])
              : null,
      entryUser: json['entrY_USER'],
      updateUser: json['updatE_USER'],
      activeFlag: json['flaG_AKTIF'],
      email: json['email'] ?? 'N/A',
      ktp: json['ktp'],
      phone1: json['phonE1'] ?? 'N/A',
      phone2: json['phonE2'],
      isApproved: json['isApproved'],
      va1: json['vA1'],
      va1Note: json['vA1NOTE'],
      totalStoreConfig: json['totalstoreconfig'],
      isBlackList: json['isBlackList'],
      // Password fields are not expected from the list API
    );
  }

  String get formattedRegisterDate =>
      registerDate != null
          ? DateFormat('dd MMM yyyy').format(registerDate!)
          : 'N/A';
  String get status =>
      activeFlag == '1' ? 'Active' : (activeFlag == '0' ? 'Inactive' : 'N/A');
}
