import 'package:flutter/material.dart';
import 'trial_balance_filter_page.dart';
import 'profit_loss_filter_page.dart';
import 'cashflow_filter_page.dart';

class DownloadReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Report')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('Trial Balance', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrialBalanceFilterPage(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.assessment_outlined, color: Colors.green),
            title: Text('Profit and Loss', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfitLossFilterPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.monetization_on, color: Colors.green),
            title: Text('Cashflow Report', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CashflowFilterPage()),
              );
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}
