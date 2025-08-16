import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/account_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

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
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse('$baseUrl/api/API/getddAccount');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _accountsList =
              data
                  .map((item) => Account.fromJson(item as Map<String, dynamic>))
                  .toList();
          _isLoadingAccounts = false;
        });
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error fetching accounts: $e");
      if (mounted) {
        setState(() {
          _accountError =
              "An error occurred fetching accounts: ${e.toString()}";
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitJournalEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null ||
        _selectedDebitAccount == null ||
        _selectedCreditAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedDebitAccount!.accountNo == _selectedCreditAccount!.accountNo) {
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
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final String formattedDate = DateFormat(
        "yyyy-MM-dd",
      ).format(_selectedDate!);
      final String amountString = _amountController.text.replaceAll('.', '');
      final double? amount = double.tryParse(amountString);

      if (amount == null || amount <= 0) {
        throw Exception('Invalid or zero amount entered.');
      }

      final int amountInt = amount.toInt();

      final body = json.encode({
        "TransDate": formattedDate,
        "Description": _descriptionController.text,
        "Akun_Debit": _selectedDebitAccount!.accountNo,
        "Akun_Credit": _selectedCreditAccount!.accountNo,
        "Debit": amountInt,
        "Credit": amountInt,
      });

      final url = Uri.parse('$baseUrl/api/API/SubmitJM');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
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
        } catch (_) {}
        throw Exception(
          'Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitError = "An error occurred: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
                ),
                maxLines: 2,
                validator:
                    (v) =>
                        v!.trim().isEmpty
                            ? 'Please enter a description.'
                            : null,
              ),
              SizedBox(height: 16),
              if (_isLoadingAccounts)
                Center(child: CircularProgressIndicator())
              else if (_accountError != null)
                Text(
                  'Error loading accounts: $_accountError',
                  style: TextStyle(color: Colors.red),
                )
              else ...[
                DropdownSearch<Account>(
                  items: _accountsList,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Account",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? acc) =>
                          setState(() => _selectedDebitAccount = acc),
                  validator:
                      (v) =>
                          v == null ? 'Please select a debit account.' : null,
                ),
                SizedBox(height: 16),
                DropdownSearch<Account>(
                  items: _accountsList,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Account",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? acc) =>
                          setState(() => _selectedCreditAccount = acc),
                  validator:
                      (v) =>
                          v == null ? 'Please select a credit account.' : null,
                ),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter an amount.';
                  final number = double.tryParse(v.replaceAll('.', ''));
                  if (number == null || number <= 0)
                    return 'Please enter a valid positive amount.';
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (_submitError != null)
                Text(
                  _submitError!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 12),
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
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
