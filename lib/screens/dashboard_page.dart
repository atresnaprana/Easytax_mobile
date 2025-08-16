import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/admin_menu_page.dart';
import 'auth/login_page.dart';
import 'download_report/download_report_page.dart';
import 'memorial_journal/memorial_journal_page.dart';
import 'purchase_journal/purchasing_journal_page.dart';
import 'sales_journal/sales_journal_page.dart';

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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigate(Widget page) {
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
                  SizedBox(height: 30),
                  Image.asset(
                    'assets/easytaxlandscape.png', // MAKE SURE THIS PATH IS CORRECT
                    height: 110,
                  ),
                  SizedBox(height: 15),
                  Text(
                    _userIdentifier ?? 'User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 25),
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
