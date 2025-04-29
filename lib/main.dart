import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // Required for TimeoutException
import 'package:intl/intl.dart'; // Required for DateFormat

const String baseUrl = 'http://192.168.100.176:13080/';

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

  // *** USES DateFormat FROM intl PACKAGE ***
  String get formattedDate => DateFormat('dd MMM yyyy').format(transDate);

  String get formattedDebit => debitStr;
  String get formattedCredit => creditStr;
}

void main() {
  runApp(MyApp());
}

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

class SplashScreen extends StatelessWidget {
  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.data == true) {
            return DashboardPage();
          } else {
            return LoginPage();
          }
        }
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  void _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    var headers = {
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse('$baseUrl/api/Auth/login'));
    request.body = json.encode({
      "username": username,
      "password": password
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      var data = json.decode(responseBody);

      String token = data['token'];

      // Save token to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('userid', username);

      await prefs.setBool('loggedIn', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
      print("Token saved: $token");
    } else {
      print(response.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: Text('Login')),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userIdentifier; // State variable to hold the email/username
  bool _isLoading = true; // To show a loading indicator initially

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data when the widget is first created
  }

  // Asynchronous function to load data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('userid'); // Use the key you saved during login

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _userIdentifier = identifier ?? 'N/A'; // Set the state variable, provide default
        _isLoading = false; // Loading finished
      });
    }
  }

  // --- Logout Method (moved inside State) ---
  void _logout() async { // Removed context parameter, use 'context' directly
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userid'); // Also remove the user identifier on logout
    await prefs.setBool('loggedIn', false);

    // Use Navigator.of(context) if inside State method
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  // --- Navigate Method (moved inside State) ---
  void _navigate(Widget page) { // Removed context parameter
    Navigator.push(
      context, // Use 'context' directly
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // --- Build Tile Method (moved inside State or could be static helper) ---
  Widget _buildTile(IconData icon, String label, Widget page) { // Removed context parameter
    return InkWell(
      onTap: () => _navigate(page), // Call the state's navigate method
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // ... decoration ... (no change needed here)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
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


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout, // Call the state's logout method
          ),
        ],
      ),
      body: _isLoading // Show loading indicator while fetching data
          ? Center(child: CircularProgressIndicator())
          : Column( // Show dashboard content once data is loaded
        children: [
          SizedBox(height: 20),
          CircleAvatar( // You can keep or remove the avatar
            radius: 40,
            backgroundImage: NetworkImage(
              'https://via.placeholder.com/150/5c6bc0/FFFFFF?text=${_userIdentifier?[0].toUpperCase() ?? 'U'}', // Use first letter of identifier for placeholder
            ),
            backgroundColor: Colors.grey.shade300,
          ),
          SizedBox(height: 10),
          // Display the loaded user identifier
          Text(
            _userIdentifier ?? 'User', // Use the state variable
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // You might want another Text widget for a full name if you save it separately
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // Call the state's _buildTile method
                _buildTile(Icons.book_outlined, 'Memorial Journal', MemorialJournalPage()),
                _buildTile(Icons.receipt_long_outlined, 'Sales Journal', SalesJournalPage()),
                _buildTile(Icons.shopping_cart_outlined, 'Purchasing Journal', PurchasingJournalPage()),
                _buildTile(Icons.download_for_offline_outlined, 'Download Report', DownloadReportPage()),
                _buildTile(Icons.admin_panel_settings_outlined, 'Admin Menu', AdminMenuPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ==========================================
// IMPLEMENTED SAMPLE PAGES (Revised)
// ==========================================

// --- Placeholder Page for Adding New Entries ---
class AddMemorialJournalEntryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Memorial Journal Entry')),
      body: Center(child: Text('Form to add new entry will be here.')),
    );
  }
}


// --- Memorial Journal Page Widget (Stateful) ---
class MemorialJournalPage extends StatefulWidget {
  @override
  _MemorialJournalPageState createState() => _MemorialJournalPageState();
}

class _MemorialJournalPageState extends State<MemorialJournalPage> {
  List<MemorialJournalEntry> _allEntries = [];
  List<MemorialJournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchJournalEntries();
  }

  // --- Asynchronous Data Fetching Method ---
  Future<void> _fetchJournalEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _allEntries.clear();
      _filteredEntries.clear();
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication required. Please log in again.');
      }

      // !!! IMPORTANT: Replace with your actual API endpoint !!!
      final url = Uri.parse('$baseUrl/api/API/getdataJM');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          // *** USES TimeoutException FROM dart:async ***
          throw TimeoutException('The request timed out. Please try again.');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allEntries = data.map((jsonItem) => MemorialJournalEntry.fromJson(jsonItem)).toList();
        _filteredEntries = List.from(_allEntries);
        _applySort();
        setState(() { _isLoading = false; });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired or unauthorized (Code: ${response.statusCode}). Please log in again.');
      } else {
        throw Exception('Failed to load data. Status Code: ${response.statusCode}\nBody: ${response.body}');
      }

      // *** CATCHES TimeoutException FROM dart:async ***
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? "Request timed out.";
        _isLoading = false;
      });
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Network error: ${e.message}.";
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching/processing journal entries: $e");
      if (!mounted) return;
      setState(() {
        _error = "An unexpected error occurred: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // --- Date Filtering Logic ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initial,
      firstDate: DateTime(2000), lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) { _startDate = picked; }
        else { _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999); }
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    if (!mounted) return;
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        bool passesStartDate = _startDate == null || !entry.transDate.isBefore(_startDate!);
        bool passesEndDate = _endDate == null || !entry.transDate.isAfter(_endDate!);
        return passesStartDate && passesEndDate;
      }).toList();
      _applySort();
    });
  }

  void _clearFilter() {
    if (!mounted) return;
    setState(() {
      _startDate = null; _endDate = null;
      _filteredEntries = List.from(_allEntries);
      _applySort();
    });
  }

  // --- Sorting Logic ---
  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortColumnIndex = columnIndex; _sortAscending = ascending;
      _applySort();
    });
  }

  void _applySort() {
    _filteredEntries.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0: compareResult = a.transDate.compareTo(b.transDate); break;
        case 1: compareResult = a.transNo.compareTo(b.transNo); break;
        case 2: compareResult = a.description.compareTo(b.description); break;
        case 3: compareResult = a.debit.compareTo(b.debit); break;
        case 4: compareResult = a.credit.compareTo(b.credit); break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }

  // --- Build Method: Constructs the UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memorial Journal'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), tooltip: 'Refresh Data',
            onPressed: _isLoading ? null : _fetchJournalEntries,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget(_error!)
          : Column(
        children: [
          _buildDateFilterRow(context),
          Expanded(child: _buildDataTable()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push( context, MaterialPageRoute(builder: (context) => AddMemorialJournalEntryPage()),
          ).then((value) { if (value == true) { _fetchJournalEntries(); } });
        },
        tooltip: 'Add New Entry', child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // --- Helper Widget Methods for UI Building ---

  Widget _buildDateFilterRow(BuildContext context) {
    // *** USES DateFormat FROM intl PACKAGE ***
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final Color primaryColor = Theme.of(context).primaryColor;

    return Padding( /* ... Rest of filter row widget ... */
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0, runSpacing: 0.0,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(_startDate == null ? 'From Date' : formatter.format(_startDate!), style: TextStyle(color: primaryColor)),
            onPressed: () => _selectDate(context, true),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
            label: Text(_endDate == null ? 'To Date' : formatter.format(_endDate!), style: TextStyle(color: primaryColor)),
            onPressed: () => _selectDate(context, false),
          ),
          if (_startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: ActionChip(
                avatar: Icon(Icons.clear, size: 16, color: Colors.black54),
                label: Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.black87)),
                onPressed: _clearFilter,
                backgroundColor: Colors.grey[200],
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 4.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTable() { /* ... Rest of data table widget ... */
    if (_filteredEntries.isEmpty && !_isLoading) {
      return Center(child: Padding( padding: const EdgeInsets.all(20.0), child: Text(
        'No entries found${(_startDate !=null || _endDate !=null) ? ' for the selected date range': ''}.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ), ) );
    }
    final List<DataColumn> columns = [ /* ... Column definitions ... */
      DataColumn(label: Text('Date'), tooltip: 'Transaction Date', onSort: _onSort),
      DataColumn(label: Text('Trans No'), tooltip: 'Transaction Number', onSort: _onSort),
      DataColumn(label: Text('Description'), tooltip: 'Transaction Description', onSort: _onSort),
      DataColumn(label: Text('Debit'), tooltip: 'Debit Amount', numeric: true, onSort: _onSort),
      DataColumn(label: Text('Credit'), tooltip: 'Credit Amount', numeric: true, onSort: _onSort),
    ];
    final List<DataRow> rows = _filteredEntries.map((entry) { /* ... Row mapping ... */
      return DataRow( cells: [
        DataCell(Text(entry.formattedDate)), DataCell(Text(entry.transNo)),
        DataCell(Text(entry.description)), DataCell(Text(entry.formattedDebit)),
        DataCell(Text(entry.formattedCredit)),
      ],);
    }).toList();
    return SingleChildScrollView( child: SingleChildScrollView( scrollDirection: Axis.horizontal,
      child: DataTable( /* ... DataTable properties ... */
        columns: columns, rows: rows,
        sortColumnIndex: _sortColumnIndex, sortAscending: _sortAscending,
        showCheckboxColumn: false, columnSpacing: 20, headingRowHeight: 40,
        dataRowMinHeight: 48, dataRowMaxHeight: 56,
        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
        headingRowColor: MaterialStateProperty.resolveWith<Color?>((_) => Colors.blueGrey[50]),
      ), ), );
  }

  Widget _buildErrorWidget(String errorMessage) { /* ... Error widget implementation ... */
    return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
        SizedBox(height: 15),
        Text('Failed to Load Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900), textAlign: TextAlign.center, ),
        SizedBox(height: 10), Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87),),
        SizedBox(height: 25),
        ElevatedButton.icon( icon: Icon(Icons.refresh), label: Text('Retry'),
          onPressed: _fetchJournalEntries,
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor),
        )
      ], ), ));
  }
} // End of _MemorialJournalPageState class

// --- Make sure the rest of your main.dart (MyApp, SplashScreen, LoginPage, DashboardPage, etc.) follows here ---

class SalesJournalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Journal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Sales Journal Entries',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Display list of sales journal entries here.'),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Dashboard'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to a "Create Sales Journal Entry" page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to Create Sale page...')),
          );
        },
        tooltip: 'New Sale',
        child: Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class PurchasingJournalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Purchasing Journal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Purchasing Journal Entries',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Display list of purchasing journal entries here.'),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Dashboard'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to a "Create Purchase Journal Entry" page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to Create Purchase page...')),
          );
        },
        tooltip: 'New Purchase',
        child: Icon(Icons.add_business_outlined),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class DownloadReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Report')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_for_offline_outlined, size: 60, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              'Download Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Provide options to select and download reports (PDF, Excel, etc.).'),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Dashboard'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

class AdminMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Menu')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 60, color: Colors.redAccent),
            SizedBox(height: 20),
            Text(
              'Administration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Display admin-specific options (User Management, Settings, etc.).'),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Dashboard'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}