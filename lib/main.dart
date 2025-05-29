import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_time_app/screens/dev_settings.dart';
import 'package:work_time_app/screens/overview_page.dart';
import 'package:work_time_app/screens/add_wt_page.dart';
import 'package:work_time_app/screens/settings_page.dart';
import 'package:work_time_app/screens/calendar_page.dart';
import 'package:work_time_app/screens/statistics_page.dart';
import 'package:work_time_app/screens/splash_screen.dart'; // Neuer Import für Splash Screen
import 'package:work_time_app/utils/WorkTimeController.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  runApp(const WorkTimeApp());
}

class WorkTimeApp extends StatelessWidget {
  const WorkTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkTimeController(), // Controller wird jetzt im Splash Screen geladen
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Work Time Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // 24h Format für alle Plattformen erzwingen (löst AM/PM Problem)
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
        initialRoute: '/splash', // Starte mit Splash Screen
        routes: {
          '/splash': (context) => const SplashScreen(), // Neue Route für Splash Screen
          '/overview_page': (context) => const OverviewPage(),
          '/add_wt_page': (context) => const AddWtPage(),
          '/settings_page': (context) => const SettingsPage(),
          '/calendar_page': (context) => const CalendarPage(),
          '/statistics_page': (context) => const StatisticsPage(),
          '/dev_settings': (context) => const DevSettingsPage(),
        },
      ),
    );
  }
}