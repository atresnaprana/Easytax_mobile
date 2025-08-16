import 'package:flutter/material.dart';
import 'account_settings/account_settings_page.dart';
import 'user_settings/user_settings_page.dart';

class AdminMenuPage extends StatelessWidget {
  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Menu')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(
              Icons.manage_accounts,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('Account Settings', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _navigate(context, AccountSettingsPage());
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.people_alt_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('User Settings', style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _navigate(context, UserSettingsPage());
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}
