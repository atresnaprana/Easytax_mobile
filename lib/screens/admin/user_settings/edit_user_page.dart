import 'dart:convert';
import 'package:flutter/material.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdateUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.isNotEmpty &&
        (_passwordController.text != _confirmPasswordController.text)) {
      setState(() => _submitError = "New passwords do not match.");
      return;
    }
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

      Map<String, dynamic> bodyMap = {
        "id": widget.user.id,
        "CUST_NAME": _nameController.text.trim(),
        "PHONE1": _phoneController.text.trim(),
        "Email": _emailController.text.trim().toLowerCase(),
        "flaG_AKTIF": _selectedActiveFlag,
        if (_passwordController.text.isNotEmpty)
          "Password": _passwordController.text,
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

      final response = await http
          .put(url, headers: headers, body: json.encode(bodyMap))
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
              SizedBox(height: 24),
              Text(
                "Change Password (Optional)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator:
                    (v) =>
                        (v!.isNotEmpty && v.length < 6)
                            ? 'Password too short (min 6)'
                            : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (_passwordController.text.isNotEmpty &&
                      v != _passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
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
