import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import 'pdf_viewer_page.dart';

class TrialBalanceFilterPage extends StatefulWidget {
  @override
  _TrialBalanceFilterPageState createState() => _TrialBalanceFilterPageState();
}

class _TrialBalanceFilterPageState extends State<TrialBalanceFilterPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  int _selectedMonth = DateTime.now().month;
  bool _isYearly = true;
  bool _isPreview = true;
  bool _isLoading = false;
  String? _downloadError;

  final List<Map<String, dynamic>> _months = [
    {'value': 1, 'name': 'January'},
    {'value': 2, 'name': 'February'},
    {'value': 3, 'name': 'March'},
    {'value': 4, 'name': 'April'},
    {'value': 5, 'name': 'May'},
    {'value': 6, 'name': 'June'},
    {'value': 7, 'name': 'July'},
    {'value': 8, 'name': 'August'},
    {'value': 9, 'name': 'September'},
    {'value': 10, 'name': 'October'},
    {'value': 11, 'name': 'November'},
    {'value': 12, 'name': 'December'},
  ];

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _downloadError = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final int? year = int.tryParse(_yearController.text);
      if (year == null) throw Exception('Invalid Year entered.');

      final String endpointPath =
          _isPreview ? '/api/API/GeneratePreviewTB' : '/api/API/GeneratePdfTB';
      final url = Uri.parse('$baseUrl$endpointPath');
      final Map<String, dynamic> bodyMap = {
        "year": year,
        "month": _isYearly ? 0 : _selectedMonth,
        "isYearly": _isYearly,
      };
      final String requestBody = json.encode(bodyMap);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        if (bytes.isEmpty) throw Exception('Received empty file from server.');

        final tempDir = await getTemporaryDirectory();
        final String reportName = 'Trial Balance';
        final String previewStatus = _isPreview ? 'Preview' : 'Closed';
        final String monthString =
            _isYearly
                ? "Yearly"
                : DateFormat('MMM').format(DateTime(0, _selectedMonth));
        final String filename =
            '${reportName.replaceAll(' ', '_')}_${year}_${monthString}_$previewStatus.pdf';
        final File file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerPage(
                  filePath: file.path,
                  reportName:
                      '$reportName ($previewStatus $year - $monthString)',
                ),
          ),
        );
      } else {
        String serverMessage = response.reasonPhrase ?? 'Download Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {}
        throw Exception(
          'Failed to download report. Server: ${response.statusCode} - $serverMessage',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _downloadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trial Balance Report')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure Report:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a year.';
                  if (value.length != 4) return 'Please enter a 4-digit year.';
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Yearly Report'),
                value: _isYearly,
                onChanged: (bool value) => setState(() => _isYearly = value),
                secondary: Icon(
                  _isYearly ? Icons.calendar_month : Icons.date_range,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 8),
              if (!_isYearly) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items:
                      _months.map((Map<String, dynamic> month) {
                        return DropdownMenuItem<int>(
                          value: month['value'],
                          child: Text(month['name']),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null)
                      setState(() => _selectedMonth = newValue);
                  },
                ),
                SizedBox(height: 16),
              ],
              SwitchListTile(
                title: Text('Preview Version'),
                subtitle: Text(
                  _isPreview
                      ? 'Get latest preview data'
                      : 'Get final closed data',
                ),
                value: _isPreview,
                onChanged: (bool value) => setState(() => _isPreview = value),
                secondary: Icon(
                  _isPreview ? Icons.visibility : Icons.lock_clock,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 30),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _downloadError!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('Generate & View PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _downloadReport(context),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
