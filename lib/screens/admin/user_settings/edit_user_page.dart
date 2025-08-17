import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';

class EditUserPage extends StatefulWidget {
  final UserEntry user;
  const EditUserPage({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String? _selectedActiveFlag;
  bool _isSubmitting = false;
  String? _submitError;

  final List<Map<String, String>> _statusOptions = [
    {'value': '1', 'display': 'Active'},
    {'value': '0', 'display': 'Inactive'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.customerName);
    _phoneController = TextEditingController(text: widget.user.phone1);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedActiveFlag = widget.user.activeFlag;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdateUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedActiveFlag == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a status.'),
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

      // --- CHANGE #1: The 'id' is removed from the bodyMap ---
      // The API gets the ID from the URL, not the body.
      Map<String, dynamic> bodyMap = {
        "CUST_NAME": _nameController.text.trim(),
        "PHONE1": _phoneController.text.trim(),
        "Email": _emailController.text.trim().toLowerCase(),
        "flaG_AKTIF": _selectedActiveFlag,
        // The password field is not sent since it was removed
        "companY_ID": widget.user.companyId,
        "npwp": widget.user.npwp,
        "address": widget.user.address,
        "city": widget.user.city,
      };

      final url = Uri.parse('$baseUrl/api/API/EditUser?id=${widget.user.id}');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      // --- CHANGE #2: The method is changed from .put to .post ---
      final response = await http
          .post(url, headers: headers, body: json.encode(bodyMap))
          .timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User updated successfully!'),
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
          'Failed to update user. Server: ${response.statusCode} - $serverMessage',
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
      appBar: AppBar(title: Text('Edit User: ${widget.user.customerName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator:
                    (v) =>
                        v!.trim().isEmpty ? 'Phone number is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.'))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedActiveFlag,
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
                onChanged: (v) => setState(() => _selectedActiveFlag = v),
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
                    label: Text('Update User'),
                    onPressed: _submitUpdateUser,
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
