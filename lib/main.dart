import 'package:flutter/material.dart'; // Should be here
import 'package:shared_preferences/shared_preferences.dart'; // Should be here
import 'dart:convert'; // Should be here
import 'package:http/http.dart' as http; // Should be here
import 'dart:async'; // Should be here
import 'package:intl/intl.dart'; // Should be here
import 'package:flutter/services.dart'; // <--- Correct position
import 'dart:math'; // <--- Correct position (needed for previous numbered pagination, keep if might reuse)

// --- Define your Base URL ---
const String baseUrl = 'http://192.168.100.176:13080/'; // ADJUST AS NEEDED

// --- Data Model Class for Memorial Journal Entry ---
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
  });

  factory MemorialJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value.replaceAll(RegExp(r'[.]'), '').replaceAll(',', '.');
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
      debitStr: json['debitStr'] ?? '0,00',
      creditStr: json['creditStr'] ?? '0,00',
      transDateStr: json['transDateStr'] ?? '',
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
  final int akunDebitdisc; // Note: These might not be used in current display/sort
  final int akunCreditdisc;// Note: These might not be used in current display/sort
  final double Value;      // Numeric value for sorting/calculations
  final double ValueDisc;  // Numeric value for discount sorting/calculations
  final String ValueStr;   // Formatted string for display
  final String ValueStrdisc;// Formatted string for display
  final String transDateStr;

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
  });

  factory PurchaseJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value.replaceAll(RegExp(r'[.]'), '').replaceAll(',', '.');
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
      Value: parseDouble(json['value']),         // Check API key ('value' or 'Value'?)
      ValueDisc: parseDouble(json['value_Disc']),  // Check API key ('value_Disc' or 'ValueDisc'?)
      ValueStr: json['valueStr'] ?? '0,00',       // Check API key
      ValueStrdisc: json['valueDiscStr'] ?? '0,00', // Check API key ('valueDiscStr'?)
      transDateStr: json['transDateStr'] ?? '',
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
  final int akunDebitdisc; // Note: These might not be used in current display/sort
  final int akunCreditdisc;// Note: These might not be used in current display/sort
  final double Value;      // Numeric value for sorting/calculations
  final double ValueDisc;  // Numeric value for discount sorting/calculations
  final String ValueStr;   // Formatted string for display
  final String ValueStrdisc;// Formatted string for display
  final String transDateStr;

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
  });

  factory SalesJournalEntry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleanedValue = value.replaceAll(RegExp(r'[.]'), '').replaceAll(',', '.');
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
      Value: parseDouble(json['value']),         // Check API key ('value' or 'Value'?)
      ValueDisc: parseDouble(json['value_Disc']),  // Check API key ('value_Disc' or 'ValueDisc'?)
      ValueStr: json['valueStr'] ?? '0,00',       // Check API key
      ValueStrdisc: json['valueDiscStr'] ?? '0,00', // Check API key ('valueDiscStr'?)
      transDateStr: json['transDateStr'] ?? '',
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
          other is Account && runtimeType == other.runtimeType && accountNo == other.accountNo;

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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
class SplashScreen extends StatelessWidget {
  Future<bool> _checkLoginStatus() async {
    await Future.delayed(Duration(milliseconds: 500));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          if (snapshot.hasError) { print("Error checking login: ${snapshot.error}"); return LoginPage(); }
          if (snapshot.data == true) { return DashboardPage(); }
          else { return LoginPage(); }
        }
      },
    );
  }
}

// --- Login Page ---
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
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) { setState(() { _error = "Username and Password cannot be empty."; _isLoading = false; }); return; }
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('$baseUrl/api/Auth/login'));
    request.body = json.encode({"username": username, "password": password});
    request.headers.addAll(headers);
    try {
      http.StreamedResponse responseStream = await request.send().timeout(Duration(seconds: 20));
      final response = await http.Response.fromStream(responseStream);
      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = json.decode(response.body); String? token = data['token'];
        if (token != null && token.isNotEmpty) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token); await prefs.setString('userid', username); await prefs.setBool('loggedIn', true);
          print("Login successful. Token saved: $token");
          Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => DashboardPage()), ); return;
        } else { _error = "Login successful, but no token received."; }
      } else { String serverMessage = response.reasonPhrase ?? 'Unknown Error'; try { var errorData = json.decode(response.body); serverMessage = errorData['message'] ?? errorData['error'] ?? serverMessage; } catch(_) { /* Ignore */ } _error = "Login failed: ${response.statusCode} - $serverMessage"; print("Login failed: ${response.statusCode} ${response.reasonPhrase}"); print("Response body: ${response.body}"); }
    } on TimeoutException { _error = "Login request timed out. Please try again."; } on http.ClientException catch (e) { _error = "Network error: ${e.message}. Please check connection."; } catch (e) { _error = "An unexpected error occurred: ${e.toString()}"; print("Login error: $e"); }
    if (mounted) { setState(() { _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center( child: SingleChildScrollView( padding: const EdgeInsets.all(24.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('EasyTax', style: Theme.of(context).textTheme.headlineMedium), SizedBox(height: 30),
        if (_error != null) Padding( padding: const EdgeInsets.only(bottom: 12.0), child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center), ),
        TextField( controller: _usernameController, decoration: InputDecoration( labelText: 'Username', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), ), keyboardType: TextInputType.text, textInputAction: TextInputAction.next, ),
        SizedBox(height: 16), TextField( controller: _passwordController, obscureText: true, decoration: InputDecoration( labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), ), textInputAction: TextInputAction.done, onSubmitted: (_) => _login(), ),
        SizedBox(height: 24), _isLoading ? CircularProgressIndicator() : ElevatedButton( onPressed: _login, child: Text('Login'), style: ElevatedButton.styleFrom( minimumSize: Size(double.infinity, 50), textStyle: TextStyle(fontSize: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) ), ),
      ], ), ), ), );
  }
}

// --- Dashboard Page ---
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userIdentifier; bool _isLoading = true;
  @override void initState() { super.initState(); _loadUserData(); }
  Future<void> _loadUserData() async { SharedPreferences prefs = await SharedPreferences.getInstance(); if (!mounted) return; setState(() { _userIdentifier = prefs.getString('userid') ?? 'N/A'; _isLoading = false; }); }
  void _logout() async { SharedPreferences prefs = await SharedPreferences.getInstance(); await prefs.remove('auth_token'); await prefs.remove('userid'); await prefs.setBool('loggedIn', false); if (!mounted) return; Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false, ); }
  void _navigate(Widget page) { Navigator.push(context, MaterialPageRoute(builder: (context) => page)); }
  Widget _buildTile(IconData icon, String label, Widget page) { return InkWell( onTap: () => _navigate(page), borderRadius: BorderRadius.circular(12), child: Container( decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 3))], ), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(icon, size: 40, color: Theme.of(context).primaryColor), SizedBox(height: 10), Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(label, style: TextStyle(fontSize: 16), textAlign: TextAlign.center), ), ], ), ), ); }
  @override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Dashboard'), actions: [ IconButton(icon: Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout), ], ), body: _isLoading ? Center(child: CircularProgressIndicator()) : Column(children: [ SizedBox(height: 20), CircleAvatar( radius: 40, backgroundImage: NetworkImage( 'https://via.placeholder.com/150/5c6bc0/FFFFFF?text=${_userIdentifier?[0].toUpperCase() ?? 'U'}', ), backgroundColor: Colors.grey.shade300, ), SizedBox(height: 10), Text(_userIdentifier ?? 'User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 20), Expanded( child: GridView.count( crossAxisCount: 2, padding: EdgeInsets.all(16), crossAxisSpacing: 16, mainAxisSpacing: 16, children: [ _buildTile(Icons.book_outlined, 'Memorial Journal', MemorialJournalPage()), _buildTile(Icons.receipt_long_outlined, 'Sales Journal', SalesJournalPage()), _buildTile(Icons.shopping_cart_outlined, 'Purchasing Journal', PurchasingJournalPage()), _buildTile(Icons.download_for_offline_outlined, 'Download Report', DownloadReportPage()), _buildTile(Icons.admin_panel_settings_outlined, 'Admin Menu', AdminMenuPage()), ], ), ), ], ), ); }
}

// ================================================================
// ADD MEMORIAL JOURNAL ENTRY PAGE
// ================================================================
class AddSalesJournalEntryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Sales Journal Entry')),
      body: Center(child: Text('Form to add new Sales entry will be here.')),
    );
  }
}
class AddPurchaseJournalEntryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Purchase Journal Entry')),
      body: Center(child: Text('Form to add new Purchase entry will be here.')),
    );
  }
}
class AddMemorialJournalEntryPage extends StatefulWidget {
  @override
  _AddMemorialJournalEntryPageState createState() => _AddMemorialJournalEntryPageState();
}

class _AddMemorialJournalEntryPageState extends State<AddMemorialJournalEntryPage> {
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
    setState(() { _isLoadingAccounts = true; _accountError = null; });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance(); String? token = prefs.getString('auth_token'); if (token == null || token.isEmpty) { throw Exception('Authentication required.'); }
      final url = Uri.parse('$baseUrl/api/API/getddAccount'); final headers = { 'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token', };
      final response = await http.get(url, headers: headers).timeout(Duration(seconds: 30)); if (!mounted) return;
      if (response.statusCode == 200) { final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes)); setState(() { _accountsList = data.map((jsonItem) => Account.fromJson(jsonItem)).toList(); _isLoadingAccounts = false; });
      } else { throw Exception('Failed to load accounts. Status Code: ${response.statusCode}'); }
    } on TimeoutException { _accountError = "Fetching accounts timed out."; } on http.ClientException catch (e) { _accountError = "Network error fetching accounts: ${e.message}."; } catch (e) { print("Error fetching accounts: $e"); _accountError = "An error occurred fetching accounts: ${e.toString()}"; } finally { if (mounted) { setState(() { _isLoadingAccounts = false; }); } }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker( context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101), );
    if (picked != null && picked != _selectedDate && mounted) { setState(() { _selectedDate = picked; }); }
  }

  Future<void> _submitJournalEntry() async {
    if (!_formKey.currentState!.validate()) { return; }
    if (_selectedDate == null || _selectedDebitAccount == null || _selectedCreditAccount == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedDebitAccount!.accountNo == _selectedCreditAccount!.accountNo) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debit and Credit accounts cannot be the same.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() { _isSubmitting = true; _submitError = null; });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) { throw Exception('Authentication required.'); }

      // --- CHANGE 1: Format date as yyyy-MM-dd ---
      final String formattedDate = DateFormat("yyyy-MM-dd").format(_selectedDate!);

      final String description = _descriptionController.text;
      final int debitAccountNo = _selectedDebitAccount!.accountNo;
      final int creditAccountNo = _selectedCreditAccount!.accountNo;
      final String amountString = _amountController.text.replaceAll('.', ''); // Remove separators
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
        "Debit": amountInt,    // Send as integer
        "Credit": amountInt,   // Send as integer
      });

      final url = Uri.parse('$baseUrl/api/API/SubmitJM');
      final headers = { 'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token', };
      print("Submitting JM: $body"); // Check the body format before sending

      final response = await http.post(url, headers: headers, body: body).timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Submit Success: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Journal entry submitted successfully!'), backgroundColor: Colors.green), );
        Navigator.pop(context, true);
      } else {
        String serverMessage = response.reasonPhrase ?? 'Submission Failed';
        try { var errorData = json.decode(response.body); serverMessage = errorData['message'] ?? errorData['title'] ?? errorData['error'] ?? serverMessage; } catch(_) { /* Ignore */ }
        // Include response body in error for better debugging
        print("Submit Failed Body: ${response.body}");
        throw Exception('Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage');
      }
    } on TimeoutException { _submitError = "Submission request timed out.";
    } on http.ClientException catch (e) { _submitError = "Network error during submission: ${e.message}.";
    } catch (e) { print("Error submitting journal entry: $e"); _submitError = "An error occurred during submission: ${e.toString()}";
    } finally { if (mounted) { setState(() { _isSubmitting = false; }); } }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Memorial Journal')),
      body: SingleChildScrollView( padding: const EdgeInsets.all(16.0), child: Form( key: _formKey, child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Transaction Date:', style: Theme.of(context).textTheme.titleMedium), SizedBox(height: 8),
        InkWell( onTap: () => _selectDate(context), child: InputDecorator( decoration: InputDecoration( border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), suffixIcon: Icon(Icons.calendar_today), ), child: Text( _selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!), style: TextStyle(fontSize: 16), ), ), ),
        SizedBox(height: 16),
        TextFormField( controller: _descriptionController, decoration: InputDecoration( labelText: 'Description', border: OutlineInputBorder(), hintText: 'Enter transaction description', ), maxLines: 2, textCapitalization: TextCapitalization.sentences, validator: (value) { if (value == null || value.trim().isEmpty) { return 'Please enter a description.'; } return null; }, ),
        SizedBox(height: 16),
        if (_isLoadingAccounts) Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator()))
        else if (_accountError != null) Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Error loading accounts: $_accountError', style: TextStyle(color: Colors.red)), )
        else ...[
            DropdownButtonFormField<Account>( value: _selectedDebitAccount, isExpanded: true, decoration: InputDecoration( labelText: 'Debit Account', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), ), hint: Text('Select Debit Account'), items: _accountsList.map((Account account) { return DropdownMenuItem<Account>( value: account, child: Text(account.accountName, overflow: TextOverflow.ellipsis), ); }).toList(), onChanged: (Account? newValue) { setState(() { _selectedDebitAccount = newValue; }); }, validator: (value) => value == null ? 'Please select a debit account.' : null, ),
            SizedBox(height: 16),
            DropdownButtonFormField<Account>( value: _selectedCreditAccount, isExpanded: true, decoration: InputDecoration( labelText: 'Credit Account', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), ), hint: Text('Select Credit Account'), items: _accountsList.map((Account account) { return DropdownMenuItem<Account>( value: account, child: Text(account.accountName, overflow: TextOverflow.ellipsis), ); }).toList(), onChanged: (Account? newValue) { setState(() { _selectedCreditAccount = newValue; }); }, validator: (value) => value == null ? 'Please select a credit account.' : null, ),
            SizedBox(height: 16),
          ],
        TextFormField( controller: _amountController, decoration: InputDecoration( labelText: 'Amount (Debit/Credit)', border: OutlineInputBorder(), hintText: 'Enter amount', ),
          keyboardType: TextInputType.number,
          inputFormatters: [ ThousandsFormatter(), ],
          validator: (value) { if (value == null || value.trim().isEmpty) { return 'Please enter an amount.'; } final cleanedValue = value.replaceAll('.', ''); final number = double.tryParse(cleanedValue); if (number == null || number <= 0) { return 'Please enter a valid positive amount.'; } return null; }, ),
        SizedBox(height: 24),
        if (_submitError != null) Padding( padding: const EdgeInsets.only(bottom: 12.0), child: Text(_submitError!, style: TextStyle(color: Colors.red), textAlign: TextAlign.center), ),
        Center( child: _isSubmitting ? CircularProgressIndicator() : ElevatedButton.icon( icon: Icon(Icons.save), label: Text('Submit Entry'), onPressed: _submitJournalEntry, style: ElevatedButton.styleFrom( padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), textStyle: TextStyle(fontSize: 16), ), ), ),
        SizedBox(height: 20),
      ], ), ), ), );
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
  List<MemorialJournalEntry> _allEntries = [];
  List<MemorialJournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchJournalEntries(isInitialLoad: true);
  }

  Future<void> _fetchJournalEntries({bool isInitialLoad = false}) async {
    if (_isFetchingMore || (!isInitialLoad && !_hasMoreData)) return;
    if (!mounted) return;
    setState(() { if (isInitialLoad) { _isLoading = true; _currentPage = 1; _allEntries.clear(); _filteredEntries.clear(); _hasMoreData = true; } else { _isFetchingMore = true; } _error = null; });
    int pageToFetch = isInitialLoad ? 1 : _currentPage + 1;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance(); String? token = prefs.getString('auth_token'); if (token == null || token.isEmpty) { throw Exception('Authentication required.'); }
      final url = Uri.parse('$baseUrl/api/API/getdataJM?page=$pageToFetch&pageSize=$_pageSize'); final headers = { 'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token', };
      final response = await http.get(url, headers: headers).timeout(Duration(seconds: 45)); if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes)); final List<MemorialJournalEntry> newEntries = data.map((jsonItem) => MemorialJournalEntry.fromJson(jsonItem)).toList();
        if (newEntries.length < _pageSize) { _hasMoreData = false; }
        _allEntries.addAll(newEntries); _currentPage = pageToFetch; _applyFilter();
      } else if (response.statusCode == 401 || response.statusCode == 403) { throw Exception('Session expired or unauthorized (Code: ${response.statusCode}).'); } else { throw Exception('Failed to load data. Status Code: ${response.statusCode}\nBody: ${response.body}'); }
    } on TimeoutException catch (e) { _error = e.message ?? "Request timed out."; } on http.ClientException catch (e) { _error = "Network error: ${e.message}."; } catch (e) { print("Error (Page $pageToFetch): $e"); _error = "An unexpected error occurred: ${e.toString()}"; } finally { if (mounted) { setState(() { _isLoading = false; _isFetchingMore = false; }); } }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial = (isStartDate ? _startDate : _endDate) ?? DateTime.now(); final DateTime? picked = await showDatePicker( context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2101), );
    if (picked != null && mounted) { setState(() { if (isStartDate) { _startDate = picked; } else { _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999); } _applyFilter(); }); }
  }

  void _applyFilter() { if (!mounted) return; setState(() { _filteredEntries = _allEntries.where((entry) { bool passesStartDate = _startDate == null || !entry.transDate.isBefore(_startDate!); bool passesEndDate = _endDate == null || !entry.transDate.isAfter(_endDate!); return passesStartDate && passesEndDate; }).toList(); _applySort(); }); }
  void _clearFilter() { if (!mounted) return; setState(() { _startDate = null; _endDate = null; _filteredEntries = List.from(_allEntries); _applySort(); }); }
  void _onSort(int columnIndex, bool ascending) { if (!mounted) return; setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; _applySort(); }); }
  void _applySort() { _filteredEntries.sort((a, b) { int compareResult = 0; switch (_sortColumnIndex) { case 0: compareResult = a.transDate.compareTo(b.transDate); break; case 1: compareResult = a.transNo.compareTo(b.transNo); break; case 2: compareResult = a.description.compareTo(b.description); break; case 3: compareResult = a.debit.compareTo(b.debit); break; case 4: compareResult = a.credit.compareTo(b.credit); break; } return _sortAscending ? compareResult : -compareResult; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text('Memorial Journal'), actions: [ IconButton( icon: Icon(Icons.refresh), tooltip: 'Refresh Data', onPressed: (_isLoading || _isFetchingMore) ? null : () => _fetchJournalEntries(isInitialLoad: true), ), ], ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton( onPressed: () { Navigator.push( context, MaterialPageRoute(builder: (context) => AddMemorialJournalEntryPage()), ).then((value) { if (value == true) { _fetchJournalEntries(isInitialLoad: true); } }); }, tooltip: 'Add New Entry', child: Icon(Icons.add), backgroundColor: Theme.of(context).primaryColor, ), );
  }

  Widget _buildBody() { if (_isLoading) { return Center(child: CircularProgressIndicator()); } if (_error != null && _allEntries.isEmpty) { return _buildErrorWidget(_error!); } return Column( children: [ _buildDateFilterRow(context), if (_error != null && _allEntries.isNotEmpty) Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("Error loading more: $_error", style: TextStyle(color: Colors.red)), ), Expanded( child: ListView( children: [ _buildDataTable(), _buildPaginationControls(), ], ), ), ], ); }
  Widget _buildDateFilterRow(BuildContext context) { final DateFormat formatter = DateFormat('dd MMM yyyy'); final Color primaryColor = Theme.of(context).primaryColor; return Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Wrap( spacing: 8.0, runSpacing: 0.0, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [ TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_startDate == null ? 'From Date' : formatter.format(_startDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, true), ), TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_endDate == null ? 'To Date' : formatter.format(_endDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, false), ), if (_startDate != null || _endDate != null) Padding( padding: const EdgeInsets.only(left: 4.0), child: ActionChip( avatar: Icon(Icons.clear, size: 16, color: Colors.black54), label: Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.black87)), onPressed: _clearFilter, backgroundColor: Colors.grey[200], visualDensity: VisualDensity.compact, padding: EdgeInsets.symmetric(horizontal: 4.0), ), ), ], ), ); }
  Widget _buildDataTable() { if (_filteredEntries.isEmpty && !_isLoading) { return Center(child: Padding( padding: const EdgeInsets.all(40.0), child: Text( 'No entries found${(_startDate !=null || _endDate !=null) ? ' for the selected date range': ''}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]), ), ) ); } final List<DataColumn> columns = [ DataColumn(label: Text('Date'), tooltip: 'Transaction Date', onSort: _onSort), DataColumn(label: Text('Trans No'), tooltip: 'Transaction Number', onSort: _onSort), DataColumn(label: Text('Description'), tooltip: 'Transaction Description', onSort: _onSort), DataColumn(label: Text('Debit'), tooltip: 'Debit Amount', numeric: true, onSort: _onSort), DataColumn(label: Text('Credit'), tooltip: 'Credit Amount', numeric: true, onSort: _onSort), ]; final List<DataRow> rows = _filteredEntries.map((entry) { return DataRow( cells: [ DataCell(Text(entry.formattedDate)), DataCell(Text(entry.transNo)), DataCell(Text(entry.description)), DataCell(Text(entry.formattedDebit)), DataCell(Text(entry.formattedCredit)), ],); }).toList(); return SingleChildScrollView( scrollDirection: Axis.horizontal, child: DataTable( columns: columns, rows: rows, sortColumnIndex: _sortColumnIndex, sortAscending: _sortAscending, showCheckboxColumn: false, columnSpacing: 20, headingRowHeight: 40, dataRowMinHeight: 48, dataRowMaxHeight: 56, headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]), headingRowColor: MaterialStateProperty.resolveWith<Color?>((_) => Colors.blueGrey[50]), ), ); }
  Widget _buildPaginationControls() { if (_hasMoreData) { return Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center( child: _isFetchingMore ? CircularProgressIndicator() : ElevatedButton( onPressed: () => _fetchJournalEntries(), child: Text('Load More'), ), ), ); } else if (_allEntries.isNotEmpty) { return Padding( padding: const EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text("End of list", style: TextStyle(color: Colors.grey))), ); } else { return SizedBox.shrink(); } }
  Widget _buildErrorWidget(String errorMessage) { return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Icon(Icons.error_outline, color: Colors.red.shade700, size: 60), SizedBox(height: 15), Text('Failed to Load Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900), textAlign: TextAlign.center, ), SizedBox(height: 10), Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87),), SizedBox(height: 25), ElevatedButton.icon( icon: Icon(Icons.refresh), label: Text('Retry'), onPressed: () => _fetchJournalEntries(isInitialLoad: true), style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor), ) ], ), )); }
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
  // --- CORRECTED: Use SalesJournalEntry type ---
  List<SalesJournalEntry> _allEntries = [];
  List<SalesJournalEntry> _filteredEntries = [];
  // ---------------------------------------------

  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchJournalEntries(isInitialLoad: true);
  }

  Future<void> _fetchJournalEntries({bool isInitialLoad = false}) async {
    if (_isFetchingMore || (!isInitialLoad && !_hasMoreData)) return;
    if (!mounted) return;
    setState(() { if (isInitialLoad) { _isLoading = true; _currentPage = 1; _allEntries.clear(); _filteredEntries.clear(); _hasMoreData = true; } else { _isFetchingMore = true; } _error = null; });
    int pageToFetch = isInitialLoad ? 1 : _currentPage + 1;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance(); String? token = prefs.getString('auth_token'); if (token == null || token.isEmpty) { throw Exception('Authentication required.'); }
      // --- Use Sales endpoint: getdataJPJ ---
      final url = Uri.parse('$baseUrl/api/API/getdataJPN?page=$pageToFetch&pageSize=$_pageSize');
      final headers = { 'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token', };
      final response = await http.get(url, headers: headers).timeout(Duration(seconds: 45)); if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        // --- CORRECTED: Map to SalesJournalEntry ---
        final List<SalesJournalEntry> newEntries = data.map((jsonItem) => SalesJournalEntry.fromJson(jsonItem)).toList();
        // ------------------------------------------
        if (newEntries.length < _pageSize) { _hasMoreData = false; }
        _allEntries.addAll(newEntries); _currentPage = pageToFetch; _applyFilter();
      } else if (response.statusCode == 401 || response.statusCode == 403) { throw Exception('Session expired or unauthorized (Code: ${response.statusCode}).'); } else { throw Exception('Failed to load data. Status Code: ${response.statusCode}\nBody: ${response.body}'); }
    } on TimeoutException catch (e) { _error = e.message ?? "Request timed out."; } on http.ClientException catch (e) { _error = "Network error: ${e.message}."; } catch (e) { print("Error fetching Sales Journal (Page $pageToFetch): $e"); _error = "An unexpected error occurred: ${e.toString()}"; } finally { if (mounted) { setState(() { _isLoading = false; _isFetchingMore = false; }); } }
  }

  // --- Filtering/Clearing (No change needed conceptually, types are now correct) ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async { final DateTime initial = (isStartDate ? _startDate : _endDate) ?? DateTime.now(); final DateTime? picked = await showDatePicker( context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2101), ); if (picked != null && mounted) { setState(() { if (isStartDate) { _startDate = picked; } else { _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999); } _applyFilter(); }); } }
  void _applyFilter() { if (!mounted) return; setState(() { _filteredEntries = _allEntries.where((entry) { bool passesStartDate = _startDate == null || !entry.transDate.isBefore(_startDate!); bool passesEndDate = _endDate == null || !entry.transDate.isAfter(_endDate!); return passesStartDate && passesEndDate; }).toList(); _applySort(); }); }
  void _clearFilter() { if (!mounted) return; setState(() { _startDate = null; _endDate = null; _filteredEntries = List.from(_allEntries); _applySort(); }); }
  void _onSort(int columnIndex, bool ascending) { if (!mounted) return; setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; _applySort(); }); }

  // --- CORRECTED Sort Logic for SalesJournalEntry ---
  void _applySort() {
    _filteredEntries.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0: compareResult = a.transDate.compareTo(b.transDate); break;
        case 1: compareResult = a.transNo.compareTo(b.transNo); break;
        case 2: compareResult = a.description.compareTo(b.description); break;
      // --- Use Sales fields: debit and credit ---
        case 3: compareResult = a.formattedValue.compareTo(b.formattedValue); break;
        case 4: compareResult = a.formattedValueDisc.compareTo(b.formattedValueDisc); break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }
  // -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CORRECTED Title ---
      appBar: AppBar( title: Text('Sales Journal'), actions: [ IconButton( icon: Icon(Icons.refresh), tooltip: 'Refresh Data', onPressed: (_isLoading || _isFetchingMore) ? null : () => _fetchJournalEntries(isInitialLoad: true), ), ], ),
      body: _buildBody(),
      // --- CORRECTED FAB for Sales ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push( context, MaterialPageRoute(builder: (context) => AddSalesJournalEntryPage()), // Navigate to Add Sales page
          ).then((value) { if (value == true) { _fetchJournalEntries(isInitialLoad: true); } });
        },
        tooltip: 'Add New Sales Entry', // Correct tooltip
        child: Icon(Icons.add_shopping_cart), // Maybe different icon?
        backgroundColor: Colors.green, // Use theme color or specific color
      ),
      // -------------------------------
    );
  }

  Widget _buildBody() { if (_isLoading) { return Center(child: CircularProgressIndicator()); } if (_error != null && _allEntries.isEmpty) { return _buildErrorWidget(_error!); } return Column( children: [ _buildDateFilterRow(context), if (_error != null && _allEntries.isNotEmpty) Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("Error loading more: $_error", style: TextStyle(color: Colors.red)), ), Expanded( child: ListView( children: [ _buildDataTable(), _buildPaginationControls(), ], ), ), ], ); }
  Widget _buildDateFilterRow(BuildContext context) { final DateFormat formatter = DateFormat('dd MMM yyyy'); final Color primaryColor = Theme.of(context).primaryColor; return Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Wrap( spacing: 8.0, runSpacing: 0.0, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [ TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_startDate == null ? 'From Date' : formatter.format(_startDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, true), ), TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_endDate == null ? 'To Date' : formatter.format(_endDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, false), ), if (_startDate != null || _endDate != null) Padding( padding: const EdgeInsets.only(left: 4.0), child: ActionChip( avatar: Icon(Icons.clear, size: 16, color: Colors.black54), label: Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.black87)), onPressed: _clearFilter, backgroundColor: Colors.grey[200], visualDensity: VisualDensity.compact, padding: EdgeInsets.symmetric(horizontal: 4.0), ), ), ], ), ); }

  // --- CORRECTED DataTable for SalesJournalEntry ---
  Widget _buildDataTable() {
    if (_filteredEntries.isEmpty && !_isLoading) { return Center(child: Padding( padding: const EdgeInsets.all(40.0), child: Text( 'No entries found${(_startDate !=null || _endDate !=null) ? ' for the selected date range': ''}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]), ), ) ); }
    // --- Adjust Column Headers ---
    final List<DataColumn> columns = [
      DataColumn(label: Text('Date'), tooltip: 'Transaction Date', onSort: _onSort),
      DataColumn(label: Text('Trans No'), tooltip: 'Transaction Number', onSort: _onSort),
      DataColumn(label: Text('Description'), tooltip: 'Transaction Description', onSort: _onSort),
      DataColumn(label: Text('Value'), tooltip: 'Debit Amount', numeric: true, onSort: _onSort), // Header uses 'Debit'
      DataColumn(label: Text('Value Disc'), tooltip: 'Credit Amount', numeric: true, onSort: _onSort), // Header uses 'Credit'
      // You might add columns for discount amounts if needed
    ];
    // --- Map to correct fields for display ---
    final List<DataRow> rows = _filteredEntries.map((entry) {
      return DataRow( cells: [
        DataCell(Text(entry.formattedDate)),
        DataCell(Text(entry.transNo)),
        DataCell(Text(entry.description)),
        DataCell(Text(entry.formattedValue)), // Use formattedDebit
        DataCell(Text(entry.formattedValueDisc)), // Use formattedCredit
      ],);
    }).toList();
    // -----------------------------------------
    return SingleChildScrollView( scrollDirection: Axis.horizontal, child: DataTable( columns: columns, rows: rows, sortColumnIndex: _sortColumnIndex, sortAscending: _sortAscending, showCheckboxColumn: false, columnSpacing: 20, headingRowHeight: 40, dataRowMinHeight: 48, dataRowMaxHeight: 56, headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]), headingRowColor: MaterialStateProperty.resolveWith<Color?>((_) => Colors.blueGrey[50]), ), );
  }
  // -----------------------------------------

  Widget _buildPaginationControls() { if (_hasMoreData) { return Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center( child: _isFetchingMore ? CircularProgressIndicator() : ElevatedButton( onPressed: () => _fetchJournalEntries(), child: Text('Load More'), ), ), ); } else if (_allEntries.isNotEmpty) { return Padding( padding: const EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text("End of list", style: TextStyle(color: Colors.grey))), ); } else { return SizedBox.shrink(); } }
  Widget _buildErrorWidget(String errorMessage) { return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Icon(Icons.error_outline, color: Colors.red.shade700, size: 60), SizedBox(height: 15), Text('Failed to Load Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900), textAlign: TextAlign.center, ), SizedBox(height: 10), Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87),), SizedBox(height: 25), ElevatedButton.icon( icon: Icon(Icons.refresh), label: Text('Retry'), onPressed: () => _fetchJournalEntries(isInitialLoad: true), style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor), ) ], ), )); }
}
class PurchasingJournalPage extends StatefulWidget {
  @override
  _PurchasingJournalPageState createState() => _PurchasingJournalPageState();
}
class _PurchasingJournalPageState extends State<PurchasingJournalPage> {
  List<PurchaseJournalEntry> _allEntries = []; List<PurchaseJournalEntry> _filteredEntries = []; bool _isLoading = true; bool _isFetchingMore = false; String? _error; DateTime? _startDate; DateTime? _endDate; int _currentPage = 1; final int _pageSize = 10; bool _hasMoreData = true; int _sortColumnIndex = 0; bool _sortAscending = true;
  @override void initState() { super.initState(); _fetchJournalEntries(isInitialLoad: true); }
  Future<void> _fetchJournalEntries({bool isInitialLoad = false}) async { if (_isFetchingMore || (!isInitialLoad && !_hasMoreData)) return; if (!mounted) return; setState(() { if (isInitialLoad) { _isLoading = true; _currentPage = 1; _allEntries.clear(); _filteredEntries.clear(); _hasMoreData = true; } else { _isFetchingMore = true; } _error = null; }); int pageToFetch = isInitialLoad ? 1 : _currentPage + 1; try { SharedPreferences prefs = await SharedPreferences.getInstance(); String? token = prefs.getString('auth_token'); if (token == null || token.isEmpty) { throw Exception('Authentication required.'); } final url = Uri.parse('$baseUrl/api/API/getdataJPB?page=$pageToFetch&pageSize=$_pageSize'); final headers = { 'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $token', }; final response = await http.get(url, headers: headers).timeout(Duration(seconds: 45)); if (!mounted) return; if (response.statusCode == 200) { final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes)); final List<PurchaseJournalEntry> newEntries = data.map((jsonItem) => PurchaseJournalEntry.fromJson(jsonItem)).toList(); if (newEntries.length < _pageSize) { _hasMoreData = false; } _allEntries.addAll(newEntries); _currentPage = pageToFetch; _applyFilter(); } else if (response.statusCode == 401 || response.statusCode == 403) { throw Exception('Session expired or unauthorized (Code: ${response.statusCode}).'); } else { throw Exception('Failed to load data. Status Code: ${response.statusCode}\nBody: ${response.body}'); } } on TimeoutException catch (e) { _error = e.message ?? "Request timed out."; } on http.ClientException catch (e) { _error = "Network error: ${e.message}."; } catch (e) { print("Error (Page $pageToFetch): $e"); _error = "An unexpected error occurred: ${e.toString()}"; } finally { if (mounted) { setState(() { _isLoading = false; _isFetchingMore = false; }); } } }
  Future<void> _selectDate(BuildContext context, bool isStartDate) async { final DateTime initial = (isStartDate ? _startDate : _endDate) ?? DateTime.now(); final DateTime? picked = await showDatePicker( context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2101), ); if (picked != null && mounted) { setState(() { if (isStartDate) { _startDate = picked; } else { _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999); } _applyFilter(); }); } }
  void _applyFilter() { if (!mounted) return; setState(() { _filteredEntries = _allEntries.where((entry) { bool passesStartDate = _startDate == null || !entry.transDate.isBefore(_startDate!); bool passesEndDate = _endDate == null || !entry.transDate.isAfter(_endDate!); return passesStartDate && passesEndDate; }).toList(); _applySort(); }); }
  void _clearFilter() { if (!mounted) return; setState(() { _startDate = null; _endDate = null; _filteredEntries = List.from(_allEntries); _applySort(); }); }
  void _onSort(int columnIndex, bool ascending) { if (!mounted) return; setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; _applySort(); }); }
  // --- CORRECTED Sort Logic for PurchaseJournalEntry ---
  void _applySort() {
    _filteredEntries.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0: compareResult = a.transDate.compareTo(b.transDate); break;
        case 1: compareResult = a.transNo.compareTo(b.transNo); break;
        case 2: compareResult = a.description.compareTo(b.description); break;
      // --- Use Purchase fields: Value and ValueDisc ---
        case 3: compareResult = a.Value.compareTo(b.Value); break;
        case 4: compareResult = a.ValueDisc.compareTo(b.ValueDisc); break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }

  @override
  Widget build(BuildContext context) { return Scaffold( appBar: AppBar( title: Text('Purchasing Journal'), actions: [ IconButton( icon: Icon(Icons.refresh), tooltip: 'Refresh Data', onPressed: (_isLoading || _isFetchingMore) ? null : () => _fetchJournalEntries(isInitialLoad: true), ), ], ), body: _buildBody(),
    // --- TODO: Create AddPurchaseJournalEntryPage ---
    floatingActionButton: FloatingActionButton( onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('TODO: Create Add Purchase Page')));
       Navigator.push( context, MaterialPageRoute(builder: (context) => AddPurchaseJournalEntryPage()), ).then((value) { if (value == true) { _fetchJournalEntries(isInitialLoad: true); } });
       }, tooltip: 'Add New Purchase Entry', child: Icon(Icons.add), backgroundColor: Theme.of(context).primaryColor, ), ); }
  Widget _buildBody() { if (_isLoading) { return Center(child: CircularProgressIndicator()); } if (_error != null && _allEntries.isEmpty) { return _buildErrorWidget(_error!); } return Column( children: [ _buildDateFilterRow(context), if (_error != null && _allEntries.isNotEmpty) Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), child: Text("Error loading more: $_error", style: TextStyle(color: Colors.red)), ), Expanded( child: ListView( children: [ _buildDataTable(), _buildPaginationControls(), ], ), ), ], ); }
  Widget _buildDateFilterRow(BuildContext context) { final DateFormat formatter = DateFormat('dd MMM yyyy'); final Color primaryColor = Theme.of(context).primaryColor; return Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Wrap( spacing: 8.0, runSpacing: 0.0, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [ TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_startDate == null ? 'From Date' : formatter.format(_startDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, true), ), TextButton.icon( style: TextButton.styleFrom(visualDensity: VisualDensity.compact), icon: Icon(Icons.calendar_today, size: 18, color: primaryColor), label: Text(_endDate == null ? 'To Date' : formatter.format(_endDate!), style: TextStyle(color: primaryColor)), onPressed: () => _selectDate(context, false), ), if (_startDate != null || _endDate != null) Padding( padding: const EdgeInsets.only(left: 4.0), child: ActionChip( avatar: Icon(Icons.clear, size: 16, color: Colors.black54), label: Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.black87)), onPressed: _clearFilter, backgroundColor: Colors.grey[200], visualDensity: VisualDensity.compact, padding: EdgeInsets.symmetric(horizontal: 4.0), ), ), ], ), ); }
  // --- CORRECTED DataTable for PurchaseJournalEntry ---
  Widget _buildDataTable() {
    if (_filteredEntries.isEmpty && !_isLoading) {
      return Center(child: Padding( padding: const EdgeInsets.all(40.0), child: Text( 'No entries found${(_startDate !=null || _endDate !=null) ? ' for the selected date range': ''}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]), ), ) );
    }
    // --- Adjust Column Headers ---
    final List<DataColumn> columns = [
      DataColumn(label: Text('Date'), tooltip: 'Transaction Date', onSort: _onSort),
      DataColumn(label: Text('Trans No'), tooltip: 'Transaction Number', onSort: _onSort),
      DataColumn(label: Text('Description'), tooltip: 'Transaction Description', onSort: _onSort),
      DataColumn(label: Text('Value'), tooltip: 'Value Amount', numeric: true, onSort: _onSort), // Header uses 'Value'
      DataColumn(label: Text('Discount'), tooltip: 'Discount Amount', numeric: true, onSort: _onSort), // Header uses 'Discount'
    ];
    // --- Map to correct fields for display ---
    final List<DataRow> rows = _filteredEntries.map((entry) {
      return DataRow( cells: [
        DataCell(Text(entry.formattedDate)),
        DataCell(Text(entry.transNo)),
        DataCell(Text(entry.description)),
        DataCell(Text(entry.formattedValue)), // Use formattedValue
        DataCell(Text(entry.formattedValueDisc)), // Use formattedValueDisc
      ],);
    }).toList();
    return SingleChildScrollView( scrollDirection: Axis.horizontal, child: DataTable( columns: columns, rows: rows, sortColumnIndex: _sortColumnIndex, sortAscending: _sortAscending, showCheckboxColumn: false, columnSpacing: 20, headingRowHeight: 40, dataRowMinHeight: 48, dataRowMaxHeight: 56, headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]), headingRowColor: MaterialStateProperty.resolveWith<Color?>((_) => Colors.blueGrey[50]), ), );
  }

  Widget _buildPaginationControls() { if (_hasMoreData) { return Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center( child: _isFetchingMore ? CircularProgressIndicator() : ElevatedButton( onPressed: () => _fetchJournalEntries(), child: Text('Load More'), ), ), ); } else if (_allEntries.isNotEmpty) { return Padding( padding: const EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text("End of list", style: TextStyle(color: Colors.grey))), ); } else { return SizedBox.shrink(); } }
  Widget _buildErrorWidget(String errorMessage) { return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Icon(Icons.error_outline, color: Colors.red.shade700, size: 60), SizedBox(height: 15), Text('Failed to Load Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900), textAlign: TextAlign.center, ), SizedBox(height: 10), Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87),), SizedBox(height: 25), ElevatedButton.icon( icon: Icon(Icons.refresh), label: Text('Retry'), onPressed: () => _fetchJournalEntries(isInitialLoad: true), style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor), ) ], ), )); }
}
class DownloadReportPage extends StatelessWidget { @override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Download Report')), body: Center(child: Text('Download Report Page - Implement Here')), ); } }
class AdminMenuPage extends StatelessWidget { @override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Admin Menu')), body: Center(child: Text('Admin Menu Page - Implement Here')), ); } }