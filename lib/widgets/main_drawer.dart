import 'package:flutter/material.dart';
import 'package:work_time_app/screens/overview_page.dart';
import 'package:work_time_app/screens/add_wt_page.dart';
import 'package:work_time_app/screens/settings_page.dart'; // Stelle sicher, dass du die SettingsPage importierst
import 'package:work_time_app/screens/calendar_page.dart'; // Stelle sicher, dass du die CalendarPage importierst
import 'package:work_time_app/screens/statistics_page.dart'; // Stelle sicher, dass du die StatisticsPage importierst

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menü',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Übersicht'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushReplacementNamed('/overview_page'); // Navigiere zur OverviewPage
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Neuer Eintrag'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushNamed('/add_wt_page'); // Navigiere zur AddWtPage
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Kalender'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushNamed('/calendar_page'); // Navigiere zur CalendarPage
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Statistiken'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushNamed('/statistics_page'); // Navigiere zur StatisticsPage
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Einstellungen'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushNamed('/settings_page'); // Navigiere zur SettingsPage
            },
          ),
          ListTile(
            leading: Icon(Icons.code),
            title: Text('Dev Settings'),
            onTap: () {
              Navigator.of(context).pop(); // Schließe das Drawer
              Navigator.of(context).pushNamed('/dev_settings'); // Navigiere zur SettingsPage
            },
          ),
        ],
      ),
    );
  }
}