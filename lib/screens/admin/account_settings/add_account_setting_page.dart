import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';

class AddAccountSettingPage extends StatefulWidget {
  @override
  _AddAccountSettingPageState createState() => _AddAccountSettingPageState();
}

class _AddAccountSettingPageState extends State<AddAccountSettingPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNoController = TextEditingController();
  final _accountNameController = TextEditingController();

  String? _selectedHierarchy;
  String? _selectedAkunDK;
  String? _selectedAkunNRLR;

  bool _isSubmitting = false;
  String? _submitError;

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
    if (!_formKey.currentState!.validate()) return;
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

      final int? accountNo = int.tryParse(_accountNoController.text);
      if (accountNo == null) throw Exception('Invalid Account Number.');

      final body = json.encode({
        "account_no": accountNo,
        "hierarchy": _selectedHierarchy,
        "account_name": _accountNameController.text.trim(),
        "akundk": _selectedAkunDK,
        "akunnrlr": _selectedAkunNRLR,
      });

      final url = Uri.parse('$baseUrl/api/API/CreateAccount');
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
            content: Text('Account added successfully!'),
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
          'Failed to add account. Server: ${response.statusCode} - $serverMessage',
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
      appBar: AppBar(title: Text('Add New Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _accountNoController,
                decoration: InputDecoration(
                  labelText: 'Account Number*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter an account number.'
                            : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Name*',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter an account name.'
                            : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedHierarchy,
                decoration: InputDecoration(
                  labelText: 'Hierarchy*',
                  border: OutlineInputBorder(),
                ),
                hint: Text('Select Hierarchy (HDR/DTL)'),
                items:
                    _hierarchyOptions
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedHierarchy = v),
                validator: (v) => v == null ? 'Please select hierarchy.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAkunDK,
                decoration: InputDecoration(
                  labelText: 'Normal Balance (D/K)*',
                  border: OutlineInputBorder(),
                ),
                hint: Text('Select D or K'),
                items:
                    _akunDKOptions
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v == 'D' ? 'D - Debit' : 'K - Kredit'),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedAkunDK = v),
                validator: (v) => v == null ? 'Please select D or K.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAkunNRLR,
                decoration: InputDecoration(
                  labelText: 'Account Type (NR/LR)*',
                  border: OutlineInputBorder(),
                ),
                hint: Text('Select NR or LR'),
                items:
                    _akunNRLROptions
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v == 'NR' ? 'NR - Neraca' : 'LR - Laba Rugi',
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedAkunNRLR = v),
                validator: (v) => v == null ? 'Please select NR or LR.' : null,
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
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Add Account'),
                    onPressed: _submitNewAccount,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
