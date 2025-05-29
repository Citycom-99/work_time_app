import 'dart:math';
import 'package:flutter/material.dart';
import 'package:work_time_app/utils/WorkTimeController.dart';
import 'package:work_time_app/widgets/main_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DevSettingsPage extends StatefulWidget {
  const DevSettingsPage({super.key});

  @override
  State<DevSettingsPage> createState() => _DevSettingsPageState();
}

class _DevSettingsPageState extends State<DevSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bestätigungsdialog anzeigen
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Rot
                      foregroundColor: const Color(0xFFFFFFFF), // Weiß
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Nein',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2), // Blau
                      foregroundColor: const Color(0xFFFFFFFF), // Weiß
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Ja',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Methode zum kompletten Zurücksetzen der App
  Future<void> _resetAllData() async {
    bool confirmed = await _showConfirmationDialog(
        'Alles zurücksetzen',
        'Sind Sie sich sicher? Alle Daten und Einstellungen werden gelöscht.'
    );

    if (confirmed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Löscht alle Daten in den SharedPreferences

      // Controller zurücksetzen
      final controller = Provider.of<WorkTimeController>(context, listen: false);
      controller.hourlyWage = '';
      controller.nightBonusEnabled = false;
      controller.nightBonusFrom = '';
      controller.nightBonusTo = '';
      controller.nightHourlyWage = '';
      controller.showVacationDays = false;
      controller.monthlyEntries.clear();
      controller.vacationDays.clear();
      controller.workEntries.clear();
      controller.totalAmount = 0.0;
      controller.notifyListeners();

      // Zeige Erfolgsmeldung
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App zurückgesetzt'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('App wurde komplett zurückgesetzt');
    }
  }

  // Methode zum Löschen aller Einträge (Arbeits- und Urlaubstage)
  Future<void> _deleteAllEntries() async {
    bool confirmed = await _showConfirmationDialog(
        'Alle Einträge löschen',
        'Sind Sie sich sicher? Alle Arbeits- und Urlaubstage werden gelöscht.'
    );

    if (confirmed) {
      final controller = Provider.of<WorkTimeController>(context, listen: false);

      // Lösche alle Einträge
      controller.monthlyEntries.clear();
      controller.vacationDays.clear();
      controller.workEntries.clear();
      controller.totalAmount = 0.0;

      // Speichere die Änderungen
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('monthlyEntries');
      await prefs.remove('vacationDays');

      controller.notifyListeners();

      // Zeige Erfolgsmeldung
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alle Einträge gelöscht'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('Alle Einträge wurden gelöscht');
    }
  }

  // Methode zum Hinzufügen von Testdaten
  Future<void> _addTestData() async {
    bool confirmed = await _showConfirmationDialog(
        'Testdaten hinzufügen',
        'Sind Sie sich sicher? Testdaten werden hinzugefügt.'
    );

    if (confirmed) {
      final controller = Provider.of<WorkTimeController>(context, listen: false);
      final currentYear = DateTime.now().year;

      // Hart kodierte Testdaten - 3 Urlaubstage
      final vacationDays = [
        DateTime(currentYear, 5, 20),  // Mai
        DateTime(currentYear, 6, 15),  // Juni (erster Tag)
        DateTime(currentYear, 6, 16),  // Juni (zweiter Tag, direkt hintereinander)
      ];

      // Hart kodierte Testdaten - 10 Arbeitstage
      final workDays = [
        // 3 Arbeitstage im Mai
        {'date': DateTime(currentYear, 5, 8), 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 16, minute: 30)},
        {'date': DateTime(currentYear, 5, 14), 'start': TimeOfDay(hour: 9, minute: 15), 'end': TimeOfDay(hour: 17, minute: 45)},
        {'date': DateTime(currentYear, 5, 28), 'start': TimeOfDay(hour: 7, minute: 30), 'end': TimeOfDay(hour: 15, minute: 0)},

        // 3 Arbeitstage im Juni
        {'date': DateTime(currentYear, 6, 5), 'start': TimeOfDay(hour: 8, minute: 45), 'end': TimeOfDay(hour: 18, minute: 15)},
        {'date': DateTime(currentYear, 6, 12), 'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 16, minute: 0)},
        {'date': DateTime(currentYear, 6, 25), 'start': TimeOfDay(hour: 7, minute: 0), 'end': TimeOfDay(hour: 16, minute: 30)},

        // 4 weitere Arbeitstage zufällig verteilt
        {'date': DateTime(currentYear, 2, 12), 'start': TimeOfDay(hour: 8, minute: 30), 'end': TimeOfDay(hour: 17, minute: 0)},
        {'date': DateTime(currentYear, 4, 18), 'start': TimeOfDay(hour: 9, minute: 30), 'end': TimeOfDay(hour: 18, minute: 45)},
        {'date': DateTime(currentYear, 8, 22), 'start': TimeOfDay(hour: 7, minute: 45), 'end': TimeOfDay(hour: 15, minute: 30)},
        {'date': DateTime(currentYear, 10, 9), 'start': TimeOfDay(hour: 8, minute: 15), 'end': TimeOfDay(hour: 17, minute: 30)},
      ];

      print('Füge 3 Urlaubstage hinzu...');
      // Füge Urlaubstage hinzu
      for (DateTime date in vacationDays) {
        final dateString = DateFormat('dd.MM.yyyy').format(date);
        await controller.addVacationDay(dateString);
        print('Urlaubstag hinzugefügt: $dateString');
      }

      print('Füge 10 Arbeitstage hinzu...');
      // Füge Arbeitstage hinzu
      for (Map<String, dynamic> workDay in workDays) {
        final date = workDay['date'] as DateTime;
        final startTime = workDay['start'] as TimeOfDay;
        final endTime = workDay['end'] as TimeOfDay;

        await controller.addWorkEntryDirectly(context, date, startTime, endTime);
        print('Arbeitstag hinzugefügt: ${DateFormat('dd.MM.yyyy').format(date)} ${startTime.format(context)}-${endTime.format(context)}');
      }

      // Aktualisiere die Anzeige
      controller.updateSelectedMonth(controller.selectedMonth);

      // Zeige Erfolgsmeldung
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test daten hinzugefügt'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('Testdaten komplett hinzugefügt: 10 Arbeitstage und 3 Urlaubstage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Entwickler Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const MainDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Entwickler Einstellungen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Button: Alles zurücksetzen
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _resetAllData,
                child: const Text(
                  'Alles zurücksetzen',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Button: Alle Einträge löschen
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _deleteAllEntries,
                child: const Text(
                  'Alle Einträge löschen',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Button: Testdaten hinzufügen
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _addTestData,
                child: const Text(
                  'Testdaten hinzufügen',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}