import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/account_model.dart';
import '../../../utils/constants.dart';

class EditAccountSettingPage extends StatefulWidget {
  final AccountSettingEntry account;
  const EditAccountSettingPage({Key? key, required this.account})
    : super(key: key);

  @override
  _EditAccountSettingPageState createState() => _EditAccountSettingPageState();
}

class _EditAccountSettingPageState extends State<EditAccountSettingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNoController;
  late TextEditingController _accountNameController;
  String? _selectedHierarchy;
  String? _selectedAkunDK;
  String? _selectedAkunNRLR;
  String? _selectedFlagAktif;
  bool _isSubmitting = false;
  String? _submitError;

  final List<String> _hierarchyOptions = ['hdr', 'dtl'];
  final List<String> _akunDKOptions = ['D', 'K', '-'];
  final List<String> _akunNRLROptions = ['NR', 'LR', '-'];
  final List<Map<String, String>> _statusOptions = [
    {'value': '1', 'display': 'Active'},
    {'value': '0', 'display': 'Inactive'},
  ];

  @override
  void initState() {
    super.initState();
    _accountNoController = TextEditingController(
      text: widget.account.accountNo.toString(),
    );
    _accountNameController = TextEditingController(
      text: widget.account.accountName,
    );
    _selectedHierarchy = widget.account.hierarchy;
    _selectedAkunDK = widget.account.akunDK;
    _selectedAkunNRLR = widget.account.akunNRLR;
    _selectedFlagAktif = widget.account.flagAktif;
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHierarchy == null ||
        _selectedAkunDK == null ||
        _selectedAkunNRLR == null ||
        _selectedFlagAktif == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please ensure all selections are made.'),
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

      final body = json.encode({
        "hierarchy": _selectedHierarchy,
        "account_name": _accountNameController.text.trim(),
        "akundk": _selectedAkunDK,
        "akunnrlr": _selectedAkunNRLR,
        "flag_aktif": _selectedFlagAktif,
      });

      final url = Uri.parse(
        '$baseUrl/api/API/EditAccount',
      ).replace(queryParameters: {'id': widget.account.id.toString()});
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String serverMessage = response.reasonPhrase ?? 'Update Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {}
        throw Exception(
          'Failed to update account. Server: ${response.statusCode} - $serverMessage',
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
      appBar: AppBar(title: Text('Edit Account: ${widget.account.accountNo}')),
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
                  labelText: 'Account Number (Read-only)',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Name*',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v!.trim().isEmpty ? 'Account name is required.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedHierarchy,
                decoration: InputDecoration(
                  labelText: 'Hierarchy*',
                  border: OutlineInputBorder(),
                ),
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
                  labelText: 'Normal Balance (D/K/-)*',
                  border: OutlineInputBorder(),
                ),
                items:
                    _akunDKOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedAkunDK = v),
                validator:
                    (v) => v == null ? 'Please select normal balance.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAkunNRLR,
                decoration: InputDecoration(
                  labelText: 'Account Type (NR/LR/-)*',
                  border: OutlineInputBorder(),
                ),
                items:
                    _akunNRLROptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedAkunNRLR = v),
                validator:
                    (v) => v == null ? 'Please select account type.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFlagAktif,
                decoration: InputDecoration(
                  labelText: 'Status*',
                  border: OutlineInputBorder(),
                ),
                items:
                    _statusOptions
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['display']!),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedFlagAktif = v),
                validator: (v) => v == null ? 'Please select a status.' : null,
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
                    icon: Icon(Icons.save_alt),
                    label: Text('Update Account'),
                    onPressed: _updateAccount,
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
