import 'package:flutter/material.dart';
import '../../../models/account_model.dart';

class ViewAccountSettingPage extends StatelessWidget {
  final AccountSettingEntry account;
  const ViewAccountSettingPage({Key? key, required this.account})
    : super(key: key);

  Widget _buildDetailRow(String label, String? value) {
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
          Expanded(child: Text(value ?? 'N/A', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Account: ${account.accountNo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Account Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(height: 30),
                _buildDetailRow('Account ID', account.id.toString()),
                _buildDetailRow('Account Number', account.accountNo.toString()),
                _buildDetailRow('Account Name', account.accountName),
                _buildDetailRow('Hierarchy', account.hierarchy?.toUpperCase()),
                _buildDetailRow('Normal Balance', account.akunDK),
                _buildDetailRow('Account Type', account.akunNRLR),
                _buildDetailRow('Status', account.status),
                Divider(height: 30),
                _buildDetailRow('Entry User', account.entryUser),
                _buildDetailRow('Entry Date', account.formattedEntryDate),
                _buildDetailRow('Update User', account.updateUser),
                _buildDetailRow('Update Date', account.formattedUpdateDate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
