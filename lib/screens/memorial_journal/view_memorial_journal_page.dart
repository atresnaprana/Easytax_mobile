import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/account_model.dart';
import '../../models/journal_models.dart';
import '../../utils/constants.dart';

class ViewMemorialJournalEntryPage extends StatefulWidget {
  final int entryId;
  const ViewMemorialJournalEntryPage({Key? key, required this.entryId})
    : super(key: key);

  @override
  _ViewMemorialJournalEntryPageState createState() =>
      _ViewMemorialJournalEntryPageState();
}

class _ViewMemorialJournalEntryPageState
    extends State<ViewMemorialJournalEntryPage> {
  MemorialJournalEntry? _entry;
  String? _debitAccountName;
  String? _creditAccountName;
  bool _isLoadingData = true;
  String? _fetchError;

  // Static cache for account list
  static List<Account> _allAccountsCache = [];
  static bool _accountsCachePopulated = false;
  static bool _isFetchingAccountsGlobal = false;

  @override
  void initState() {
    super.initState();
    _fetchEntryAndAccountDetails();
  }

  Future<void> _fetchAllAccountsIfNeeded() async {
    if (_accountsCachePopulated || _isFetchingAccountsGlobal) return;
    _isFetchingAccountsGlobal = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Auth token missing for accounts fetch.');

      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allAccountsCache =
            data
                .map((item) => Account.fromJson(item as Map<String, dynamic>))
                .toList();
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

      final url = Uri.parse('$baseUrl/api/API/ViewJM?id=${widget.entryId}');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http
          .post(url, headers: headers)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final fetchedEntry = MemorialJournalEntry.fromJson(data);

        String? debitName = "Acc: ${fetchedEntry.akunDebit}";
        String? creditName = "Acc: ${fetchedEntry.akunCredit}";

        if (_accountsCachePopulated) {
          final debitAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunDebit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunDebit,
                  accountName: '(Unknown)',
                ),
          );
          debitName = debitAcc.accountName;

          final creditAcc = _allAccountsCache.firstWhere(
            (acc) => acc.accountNo == fetchedEntry.akunCredit,
            orElse:
                () => Account(
                  accountNo: fetchedEntry.akunCredit,
                  accountName: '(Unknown)',
                ),
          );
          creditName = creditAcc.accountName;
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
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (e) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading details: ${_fetchError ?? "Entry not found."}',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchEntryAndAccountDetails,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final entry = _entry!;
    return Scaffold(
      appBar: AppBar(title: Text('Journal Detail: ${entry.transNo}')),
      body: RefreshIndicator(
        onRefresh: _fetchEntryAndAccountDetails,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2.0,
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
                    '${_debitAccountName ?? entry.akunDebit}',
                  ),
                  _buildDetailRow(
                    'Debit Amount',
                    entry.formattedDebit,
                    isAmount: true,
                  ),
                  SizedBox(height: 10),
                  _buildDetailRow(
                    'Credit Account',
                    '${_creditAccountName ?? entry.akunCredit}',
                  ),
                  _buildDetailRow(
                    'Credit Amount',
                    entry.formattedCredit,
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
