import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/account_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AddPurchaseJournalEntryPage extends StatefulWidget {
  @override
  _AddPurchaseJournalEntryPageState createState() =>
      _AddPurchaseJournalEntryPageState();
}

class _AddPurchaseJournalEntryPageState
    extends State<AddPurchaseJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _valueDiscController = TextEditingController();

  DateTime? _selectedDate;
  List<Account> _accountsList = [];
  Account? _selectedDebitAccount;
  Account? _selectedCreditAccount;
  Account? _selectedDebitAccountDisc;
  Account? _selectedCreditAccountDisc;

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
    _valueDiscController.dispose();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _accountError = e.toString();
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
            content: Text(
              'Please fill Date, Debit Account, and Credit Account.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
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
      final String valueString = _valueController.text.replaceAll('.', '');
      final String valueDiscString = _valueDiscController.text.replaceAll(
        '.',
        '',
      );
      final double? amount = double.tryParse(valueString);
      final double amountdisc = double.tryParse(valueDiscString) ?? 0.0;

      if (amount == null || amount <= 0) {
        throw Exception('Invalid or zero amount entered for Value.');
      }

      final int amountInt = amount.toInt();
      final int amountdiscInt = amountdisc.toInt();

      final int debitAccountNoDisc =
          (amountdiscInt != 0 && _selectedDebitAccountDisc != null)
              ? _selectedDebitAccountDisc!.accountNo
              : 0;
      final int creditAccountNoDisc =
          (amountdiscInt != 0 && _selectedCreditAccountDisc != null)
              ? _selectedCreditAccountDisc!.accountNo
              : 0;

      final body = json.encode({
        "TransDate": formattedDate,
        "Description": _descriptionController.text,
        "Akun_Debit": _selectedDebitAccount!.accountNo,
        "Akun_Credit": _selectedCreditAccount!.accountNo,
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

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
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
        } catch (_) {}
        throw Exception(
          'Failed to submit entry. Server Response: ${response.statusCode} - $serverMessage',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter a description.'
                            : null,
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
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccount,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Account",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? newValue) =>
                          setState(() => _selectedDebitAccount = newValue),
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a debit account.'
                              : null,
                ),
                SizedBox(height: 16),
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccount,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Account",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? newValue) =>
                          setState(() => _selectedCreditAccount = newValue),
                  validator:
                      (value) =>
                          value == null
                              ? 'Please select a credit account.'
                              : null,
                ),
                SizedBox(height: 16),
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedDebitAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Debit Disc Account (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? newValue) =>
                          setState(() => _selectedDebitAccountDisc = newValue),
                ),
                SizedBox(height: 16),
                DropdownSearch<Account>(
                  items: _accountsList,
                  selectedItem: _selectedCreditAccountDisc,
                  itemAsString: (Account acc) => acc.accountName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Credit Disc Account (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.menu(showSearchBox: true),
                  onChanged:
                      (Account? newValue) =>
                          setState(() => _selectedCreditAccountDisc = newValue),
                ),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter an amount for Value.';
                  final cleanedValue = value.replaceAll('.', '');
                  final number = double.tryParse(cleanedValue);
                  if (number == null || number <= 0)
                    return 'Please enter a valid positive amount for Value.';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _valueDiscController,
                decoration: InputDecoration(
                  labelText: 'Value Disc (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
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
