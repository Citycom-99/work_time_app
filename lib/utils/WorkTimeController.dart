import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkTimeController extends ChangeNotifier {
  // Konstanten
  static const Duration SNACKBAR_DURATION = Duration(seconds: 2);
  static const Duration SNACKBAR_WARNING_DURATION = Duration(seconds: 3);
  static const Color SNACKBAR_SUCCESS_COLOR = Colors.green;
  static const Color SNACKBAR_WARNING_COLOR = Colors.orange;
  static const Duration NIGHT_CALCULATION_INTERVAL = Duration(minutes: 30);
  static const TimeOfDay DEFAULT_NIGHT_START = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay DEFAULT_NIGHT_END = TimeOfDay(hour: 6, minute: 0);
  static const TimeOfDay DEFAULT_START_TIME = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay DEFAULT_END_TIME = TimeOfDay(hour: 17, minute: 0);

  // Instanzvariablen
  String hourlyWage = '';
  double totalAmount = 0.0;
  Map<String, List<Map<String, String>>> monthlyEntries = {};
  Map<String, List<String>> vacationDays = {}; // Separate Urlaubsliste
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Map<String, String>> workEntries = [];
  bool showVacationDays = false; // Checkbox für Urlaubsanzeige

  bool nightBonusEnabled = false;
  String nightBonusFrom = '';
  String nightBonusTo = '';
  String nightHourlyWage = '';

  WorkTimeController();

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      hourlyWage = prefs.getString('hourlyWage') ?? '';
      nightBonusEnabled = prefs.getBool('nightBonusEnabled') ?? false;
      nightBonusFrom = prefs.getString('nightBonusFrom') ?? '';
      nightBonusTo = prefs.getString('nightBonusTo') ?? '';
      nightHourlyWage = prefs.getString('nightHourlyWage') ?? '';
      showVacationDays = prefs.getBool('showVacationDays') ?? false;

      await _loadMonthlyEntries(prefs);
      await _loadVacationDays(prefs);

      // Force update nach dem Laden der monatlichen Einträge
      selectedMonth = ''; // Reset to force update
      updateSelectedMonth('Alle');

      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Laden der Einstellungen: $e');
    }
  }

  Future<void> _loadVacationDays(SharedPreferences prefs) async {
    List<String>? savedVacationData = prefs.getStringList('vacationDays');
    if (savedVacationData != null) {
      vacationDays.clear();
      for (String entry in savedVacationData) {
        try {
          Map<String, dynamic> map = json.decode(entry);
          String month = map['month'];
          List<String> days = List<String>.from(map['days']);
          vacationDays[month] = days;
        } catch (e) {
          debugPrint('Fehler beim Laden der Urlaubstage: $e');
        }
      }
    }
  }

  Future<void> _loadMonthlyEntries(SharedPreferences prefs) async {
    List<String>? savedMonthlyData = prefs.getStringList('monthlyEntries');
    if (savedMonthlyData != null) {
      monthlyEntries.clear();
      for (String entry in savedMonthlyData) {
        try {
          Map<String, dynamic> map = json.decode(entry);
          String month = map['month'];
          List<Map<String, String>> entries = List<Map<String, String>>.from(
            (map['entries'] as List).map((e) => Map<String, String>.from(e)),
          );
          monthlyEntries[month] = entries;
        } catch (e) {
          debugPrint('Fehler beim Laden der monatlichen Einträge: $e');
        }
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('hourlyWage', hourlyWage);
      await prefs.setBool('nightBonusEnabled', nightBonusEnabled);
      await prefs.setString('nightBonusFrom', nightBonusFrom);
      await prefs.setString('nightBonusTo', nightBonusTo);
      await prefs.setString('nightHourlyWage', nightHourlyWage);
      await prefs.setBool('showVacationDays', showVacationDays);

      List<String> encodedMonthlyData = monthlyEntries.entries.map((e) {
        return json.encode({
          'month': e.key,
          'entries': e.value,
        });
      }).toList();

      List<String> encodedVacationData = vacationDays.entries.map((e) {
        return json.encode({
          'month': e.key,
          'days': e.value,
        });
      }).toList();

      await prefs.setStringList('monthlyEntries', encodedMonthlyData);
      await prefs.setStringList('vacationDays', encodedVacationData);
    } catch (e) {
      debugPrint('Fehler beim Speichern der Einstellungen: $e');
    }
  }

  Future<void> saveSettings() async {
    await _saveSettings(); // Ruft die private Methode auf
    notifyListeners(); // UI aktualisieren
  }

  void updateSelectedMonth(String month) {
    selectedMonth = month;

    // Lade zuerst nur die Arbeitseinträge
    if (month == 'Alle') {
      workEntries = monthlyEntries.values.expand((e) => e).toList();
    } else {
      workEntries = List<Map<String, String>>.from(monthlyEntries[month] ?? []);
    }

    // Füge Urlaubstage nur hinzu wenn die Checkbox aktiviert ist
    if (showVacationDays) {
      _addVacationEntriesToWorkEntries(month);
    }

    _sortEntriesByDate(workEntries);
    _recalculateTotalAmount();
    notifyListeners();
  }

  void _addVacationEntriesToWorkEntries(String month) {
    if (month == 'Alle') {
      // Alle Urlaubstage hinzufügen
      for (var monthEntry in vacationDays.entries) {
        for (String dayString in monthEntry.value) {
          workEntries.add({
            'date': dayString,
            'time': 'Urlaub',
            'amount': '0,00',
            'type': 'vacation',
          });
        }
      }
    } else {
      // Nur Urlaubstage des ausgewählten Monats hinzufügen
      if (vacationDays.containsKey(month)) {
        for (String dayString in vacationDays[month]!) {
          workEntries.add({
            'date': dayString,
            'time': 'Urlaub',
            'amount': '0,00',
            'type': 'vacation',
          });
        }
      }
    }
  }

  void toggleVacationDisplay() {
    showVacationDays = !showVacationDays;
    _saveSettings();
    // Force update durch temporäres Zurücksetzen
    String currentMonth = selectedMonth;
    selectedMonth = '';
    updateSelectedMonth(currentMonth);
  }

  bool isVacationDay(String dateString) {
    try {
      final date = DateFormat('dd.MM.yyyy').parse(dateString);
      final monthKey = DateFormat('yyyy-MM').format(date);

      return vacationDays.containsKey(monthKey) &&
          vacationDays[monthKey]!.contains(dateString);
    } catch (e) {
      return false;
    }
  }

  void _sortEntriesByDate(List<Map<String, String>> entries) {
    entries.sort((a, b) {
      try {
        DateTime dateA = DateFormat('dd.MM.yyyy').parse(a['date']!);
        DateTime dateB = DateFormat('dd.MM.yyyy').parse(b['date']!);
        return dateA.compareTo(dateB);
      } catch (e) {
        debugPrint('Fehler beim Sortieren der Daten: $e');
        return 0;
      }
    });
  }

  Widget buildDataTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 25.0,
            columns: const [
              DataColumn(label: Text('Datum')),
              DataColumn(label: Text('Arbeitszeit')),
              DataColumn(label: Text('Betrag')),
              DataColumn(label: Text('')),
            ],
            rows: List.generate(workEntries.length, (index) {
              final entry = workEntries[index];
              return DataRow(
                cells: [
                  DataCell(
                    Text(entry['date']!),
                    onTap: () => _showDatePicker(context, index, entry),
                  ),
                  DataCell(
                    Text(entry['time']!.replaceAll(RegExp(r'\s+'), '').trim()),
                    onTap: () => _showTimePicker(context, index, entry),
                  ),
                  DataCell(Text('${entry['amount']!}€')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteWorkEntry(context, index),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, int index, Map<String, String> entry) async {
    try {
      DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateFormat('dd.MM.yyyy').parse(entry['date']!),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (selectedDate != null) {
        entry['date'] = DateFormat('dd.MM.yyyy').format(selectedDate);
        await _saveSettings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fehler beim Datum-Picker: $e');
    }
  }

  void _showTimePicker(BuildContext context, int index, Map<String, String> entry) async {
    try {
      final timeParts = entry['time']!.split(' - ');
      TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(timeParts[0])),
      );

      if (startTime != null) {
        TimeOfDay? endTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(timeParts[1])),
        );

        if (endTime != null) {
          entry['time'] = '${startTime.format(context)} - ${endTime.format(context)}';
          await _saveSettings();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Zeit-Picker: $e');
    }
  }

  void openSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: hourlyWage);
    final nightWageController = TextEditingController(text: nightHourlyWage);
    final fromController = TextEditingController(text: nightBonusFrom);
    final toController = TextEditingController(text: nightBonusTo);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Einstellungen'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '€ pro Stunde'),
                ),
                CheckboxListTile(
                  title: const Text('Nachtzuschlag'),
                  value: nightBonusEnabled,
                  onChanged: (value) {
                    setState(() => nightBonusEnabled = value ?? false);
                  },
                ),
                if (nightBonusEnabled) ...[
                  const Text('Zeitraum für Nachtzuschlag',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: nightWageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Nacht-Stundenlohn (€)'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fromController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Von'),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: DEFAULT_NIGHT_START,
                            );
                            if (time != null) {
                              fromController.text = time.hour.toString();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: toController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Bis'),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: DEFAULT_NIGHT_END,
                            );
                            if (time != null) {
                              toController.text = time.hour.toString();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Rot
                      foregroundColor: const Color(0xFFFFFFFF), // Weiß
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Abbrechen',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () async {
                      hourlyWage = controller.text;
                      nightHourlyWage = nightWageController.text;
                      nightBonusFrom = fromController.text;
                      nightBonusTo = toController.text;

                      await _saveSettings();
                      Navigator.of(ctx).pop();
                      notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2), // Blau
                      foregroundColor: const Color(0xFFFFFFFF), // Weiß
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Speichern',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addWorkEntry(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentHourlyWage = prefs.getString('hourlyWage') ?? '';

      if (!_isValidWage(currentHourlyWage)) {
        _showSnackBar(context, 'Bitte zuerst einen Stundenlohn festlegen', SNACKBAR_WARNING_COLOR, SNACKBAR_WARNING_DURATION);
        return;
      }

      final selectedDate = await _selectDate(context);
      if (selectedDate == null) return;

      // Prüfe auf Urlaubskonflikt
      final dateString = DateFormat('dd.MM.yyyy').format(selectedDate);
      if (isVacationDay(dateString)) {
        _showSnackBar(context, 'Arbeitstag überschneidet mit Urlaub', SNACKBAR_WARNING_COLOR, SNACKBAR_WARNING_DURATION);
        return;
      }

      final timeRange = await _selectTimeRange(context);
      if (timeRange == null) return;

      final amount = await _calculateAmount(selectedDate, timeRange, prefs);
      await _saveWorkEntry(context, selectedDate, timeRange, amount);

    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Arbeitseintrags: $e');
    }
  }

  Future<void> addWorkEntryDirectly(BuildContext context, DateTime selectedDate, TimeOfDay startTime, TimeOfDay endTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentHourlyWage = prefs.getString('hourlyWage') ?? '';
      String currentNightHourlyWage = prefs.getString('nightHourlyWage') ?? '';
      bool currentNightBonusEnabled = prefs.getBool('nightBonusEnabled') ?? false;
      String currentNightBonusFrom = prefs.getString('nightBonusFrom') ?? '';
      String currentNightBonusTo = prefs.getString('nightBonusTo') ?? '';

      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime.hour, startTime.minute);

      // Prüfe ob Endzeit am nächsten Tag ist (über Mitternacht)
      DateTime end;
      if (endTime.hour < startTime.hour) {
        // Endzeit ist am nächsten Tag
        end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, endTime.hour, endTime.minute);
      } else {
        // Endzeit ist am gleichen Tag
        end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime.hour, endTime.minute);
      }

      debugPrint('=== ADD WORK ENTRY DIRECTLY ===');
      debugPrint('Start: ${DateFormat('dd.MM.yyyy HH:mm').format(start)}');
      debugPrint('End: ${DateFormat('dd.MM.yyyy HH:mm').format(end)}');

      double regularWage = double.tryParse(currentHourlyWage.replaceAll(',', '.')) ?? 0.0;
      double nightWage = double.tryParse(currentNightHourlyWage.replaceAll(',', '.')) ?? regularWage;

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        debugPrint('Fehler: Endzeit liegt vor oder ist gleich der Startzeit');
        return;
      }

      double amount = 0.0;

      debugPrint('Settings: RegularWage=$regularWage, NightWage=$nightWage, NightBonus=$currentNightBonusEnabled');
      debugPrint('Night hours: $currentNightBonusFrom to $currentNightBonusTo');

      if (currentNightBonusEnabled && currentNightBonusFrom.isNotEmpty && currentNightBonusTo.isNotEmpty) {
        amount = _calculateWithNightBonus(start, end, regularWage, nightWage, currentNightBonusFrom, currentNightBonusTo);
      } else {
        double totalHours = end.difference(start).inMinutes / 60.0;
        amount = totalHours * regularWage;
        debugPrint('No night bonus: ${totalHours}h × $regularWage = $amount');
      }

      debugPrint('Final calculated amount: $amount');

      // Formatierung der Daten
      String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);
      String formattedTime = '${startTime.format(context)} - ${endTime.format(context)}';
      String formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');

      debugPrint('Formatted: Date=$formattedDate, Time=$formattedTime, Amount=$formattedAmount');

      // Erstelle den neuen Eintrag
      Map<String, String> newEntry = {
        'date': formattedDate,
        'time': formattedTime,
        'amount': formattedAmount,
      };

      // Speichere im entsprechenden Monat
      String monthKey = DateFormat('yyyy-MM').format(selectedDate);
      monthlyEntries.putIfAbsent(monthKey, () => []);
      monthlyEntries[monthKey]!.add(newEntry);

      _sortEntriesByDate(monthlyEntries[monthKey]!);

      // Füge zur aktuellen Ansicht hinzu falls passend
      if (selectedMonth == 'Alle' || selectedMonth == monthKey) {
        workEntries.add(newEntry);
        _sortEntriesByDate(workEntries);
      }

      await _saveSettings();
      _recalculateTotalAmount();
      notifyListeners();

      debugPrint('=== WORK ENTRY ADDED SUCCESSFULLY ===');

    } catch (e) {
      debugPrint('Fehler beim direkten Hinzufügen des Arbeitseintrags: $e');
    }
  }

  Future<void> addVacationDay(String dateString) async {
    try {
      final date = DateFormat('dd.MM.yyyy').parse(dateString);
      final monthKey = DateFormat('yyyy-MM').format(date);

      vacationDays.putIfAbsent(monthKey, () => []);
      if (!vacationDays[monthKey]!.contains(dateString)) {
        vacationDays[monthKey]!.add(dateString);
        vacationDays[monthKey]!.sort((a, b) {
          DateTime dateA = DateFormat('dd.MM.yyyy').parse(a);
          DateTime dateB = DateFormat('dd.MM.yyyy').parse(b);
          return dateA.compareTo(dateB);
        });

        await _saveSettings();
        updateSelectedMonth(selectedMonth); // Aktualisiere die Anzeige
      }
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Urlaubstags: $e');
    }
  }

  Future<void> removeVacationDay(String dateString) async {
    try {
      final date = DateFormat('dd.MM.yyyy').parse(dateString);
      final monthKey = DateFormat('yyyy-MM').format(date);

      debugPrint('=== ENTFERNE URLAUBSTAG ===');
      debugPrint('Date: $dateString');
      debugPrint('Month key: $monthKey');
      debugPrint('Vacation days before: ${vacationDays[monthKey]}');

      if (vacationDays.containsKey(monthKey)) {
        vacationDays[monthKey]!.remove(dateString);
        debugPrint('Vacation days after remove: ${vacationDays[monthKey]}');

        // Entferne den Monat wenn er leer ist
        if (vacationDays[monthKey]!.isEmpty) {
          vacationDays.remove(monthKey);
          debugPrint('Month $monthKey removed (was empty)');
        }

        await _saveSettings();
        debugPrint('Settings saved');
      } else {
        debugPrint('Month key $monthKey not found in vacationDays');
      }
      debugPrint('=== URLAUBSTAG ENTFERNT ===');
    } catch (e) {
      debugPrint('Fehler beim Entfernen des Urlaubstags: $e');
    }
  }

  bool _isValidWage(String wage) {
    if (wage.isEmpty) return false;
    final parsedWage = double.tryParse(wage.replaceAll(',', '.'));
    return parsedWage != null && parsedWage > 0.0;
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime initialDate;

    if (selectedMonth == 'Alle') {
      // In "Alle" Ansicht: aktuelles Datum
      initialDate = DateTime.now();
    } else {
      // In spezifischem Monat: 1. Tag des ausgewählten Monats
      final parts = selectedMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      initialDate = DateTime(year, month, 1);
    }

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
  }

  Future<Map<String, TimeOfDay>?> _selectTimeRange(BuildContext context) async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: DEFAULT_START_TIME,
    );

    if (startTime == null) return null;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: DEFAULT_END_TIME,
    );

    if (endTime == null) return null;

    return {'start': startTime, 'end': endTime};
  }

  Future<double> _calculateAmount(DateTime selectedDate, Map<String, TimeOfDay> timeRange, SharedPreferences prefs) async {
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        timeRange['start']!.hour, timeRange['start']!.minute);

    // Prüfe ob Endzeit am nächsten Tag ist (über Mitternacht)
    DateTime end;
    if (timeRange['end']!.hour < timeRange['start']!.hour) {
      // Endzeit ist am nächsten Tag
      end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1,
          timeRange['end']!.hour, timeRange['end']!.minute);
    } else {
      // Endzeit ist am gleichen Tag
      end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
          timeRange['end']!.hour, timeRange['end']!.minute);
    }

    debugPrint('=== CALCULATE AMOUNT ===');
    debugPrint('Start: ${DateFormat('dd.MM.yyyy HH:mm').format(start)}');
    debugPrint('End: ${DateFormat('dd.MM.yyyy HH:mm').format(end)}');

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      debugPrint('Fehler: Endzeit liegt vor oder ist gleich der Startzeit');
      return 0.0;
    }

    final regularWage = double.tryParse(prefs.getString('hourlyWage')?.replaceAll(',', '.') ?? '0') ?? 0.0;
    final nightWage = double.tryParse(prefs.getString('nightHourlyWage')?.replaceAll(',', '.') ?? regularWage.toString()) ?? regularWage;
    final nightBonusEnabled = prefs.getBool('nightBonusEnabled') ?? false;
    final nightFrom = prefs.getString('nightBonusFrom') ?? '';
    final nightTo = prefs.getString('nightBonusTo') ?? '';

    debugPrint('RegularWage: $regularWage, NightWage: $nightWage, NightBonus: $nightBonusEnabled');

    if (nightBonusEnabled && nightFrom.isNotEmpty && nightTo.isNotEmpty) {
      final result = _calculateWithNightBonus(start, end, regularWage, nightWage, nightFrom, nightTo);
      debugPrint('Result with night bonus: $result');
      return result;
    } else {
      final totalHours = end.difference(start).inMinutes / 60.0;
      final result = totalHours * regularWage;
      debugPrint('Result without night bonus: ${totalHours}h × $regularWage = $result');
      return result;
    }
  }

  double _calculateWithNightBonus(DateTime start, DateTime end, double regularWage,
      double nightWage, String nightFrom, String nightTo) {

    // Parse die Nachtstunden-Einstellungen
    final nightStartHour = int.tryParse(nightFrom) ?? 22;
    final nightEndHour = int.tryParse(nightTo) ?? 6;

    debugPrint('=== NACHTZUSCHLAG BERECHNUNG ===');
    debugPrint('Arbeitszeit: ${DateFormat('dd.MM.yyyy HH:mm').format(start)} bis ${DateFormat('dd.MM.yyyy HH:mm').format(end)}');
    debugPrint('Nachtstunden: ${nightStartHour}:00 bis ${nightEndHour}:00');
    debugPrint('Regulärer Lohn: ${regularWage}€/h, Nacht-Lohn: ${nightWage}€/h');

    double totalAmount = 0.0;
    DateTime current = start;

    while (current.isBefore(end)) {
      // Berechne das Ende der aktuellen Stunde (oder Arbeitsende, falls früher)
      DateTime nextHour = DateTime(current.year, current.month, current.day, current.hour + 1, 0);
      DateTime actualNext = nextHour.isAfter(end) ? end : nextHour;

      // Berechne die Minuten in diesem Zeitraum
      double minutesWorked = actualNext.difference(current).inMinutes.toDouble();
      double hoursWorked = minutesWorked / 60.0;

      // Prüfe ob aktuelle Stunde in der Nachtzeit liegt
      bool isNightHour = _isNightHour(current.hour, nightStartHour, nightEndHour);
      double wageForThisHour = isNightHour ? nightWage : regularWage;

      double amountForThisHour = hoursWorked * wageForThisHour;
      totalAmount += amountForThisHour;

      debugPrint('${current.hour}:${current.minute.toString().padLeft(2, '0')}-${actualNext.hour}:${actualNext.minute.toString().padLeft(2, '0')}: ${hoursWorked.toStringAsFixed(2)}h × ${wageForThisHour}€ = ${amountForThisHour.toStringAsFixed(2)}€ ${isNightHour ? '(NACHT)' : '(TAG)'}');

      current = actualNext;
    }

    debugPrint('Gesamtverdienst: ${totalAmount.toStringAsFixed(2)}€');
    debugPrint('=== BERECHNUNG ENDE ===');

    return totalAmount;
  }

  bool _isNightHour(int hour, int nightStart, int nightEnd) {
    if (nightStart < nightEnd) {
      // Nachtstunden innerhalb eines Tages (z.B. 22:00 - 06:00 des GLEICHEN Tages - unwahrscheinlich)
      return hour >= nightStart && hour < nightEnd;
    } else {
      // Nachtstunden über Mitternacht (z.B. 22:00 - 06:00 des NÄCHSTEN Tages)
      return hour >= nightStart || hour < nightEnd;
    }
  }

  Future<void> _saveWorkEntry(BuildContext context, DateTime selectedDate, Map<String, TimeOfDay> timeRange, double amount) async {
    final formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);
    final formattedTime = '${timeRange['start']!.format(context)} - ${timeRange['end']!.format(context)}';
    final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');

    final newEntry = {
      'date': formattedDate,
      'time': formattedTime,
      'amount': formattedAmount,
    };

    final monthKey = DateFormat('yyyy-MM').format(selectedDate);
    monthlyEntries.putIfAbsent(monthKey, () => []);
    monthlyEntries[monthKey]!.add(newEntry);

    _sortEntriesByDate(monthlyEntries[monthKey]!);

    if (selectedMonth == 'Alle' || selectedMonth == monthKey) {
      workEntries.add(newEntry);
      _sortEntriesByDate(workEntries);
    }

    await _saveSettings();
    _recalculateTotalAmount();
    notifyListeners();
  }

  void _deleteWorkEntry(BuildContext context, int index) {
    if (workEntries.isEmpty || index < 0 || index >= workEntries.length) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Eintrag löschen'),
          content: const Text('Möchten Sie den Eintrag wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Schließe Dialog ohne zu löschen
              },
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Schließe Dialog zuerst
                _confirmDeleteWorkEntry(context, index); // Dann lösche den Eintrag
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteWorkEntry(BuildContext context, int index) {
    try {
      final entry = workEntries[index];
      final entryDate = entry['date']!;

      // Prüfe ob es ein Urlaubseintrag ist
      if (entry['type'] == 'vacation' || entry['time'] == 'Urlaub') {
        // Entferne Urlaubstag
        removeVacationDay(entryDate);
        debugPrint('Urlaubstag entfernt: $entryDate');
      } else {
        // Normaler Arbeitseintrag
        final entryMonth = DateFormat('yyyy-MM').format(DateFormat('dd.MM.yyyy').parse(entryDate));

        monthlyEntries[entryMonth]?.removeWhere((e) =>
        e['date'] == entry['date'] &&
            e['time'] == entry['time'] &&
            e['amount'] == entry['amount']);

        // Entferne leeren Monat falls nötig
        if (monthlyEntries[entryMonth]?.isEmpty == true) {
          monthlyEntries.remove(entryMonth);
        }
      }

      // Entferne den Eintrag direkt aus der workEntries Liste
      workEntries.removeAt(index);

      _saveSettings();
      _recalculateTotalAmount();
      notifyListeners(); // Direkte UI-Aktualisierung

      _showSnackBar(context, 'Eintrag wurde gelöscht', SNACKBAR_SUCCESS_COLOR, SNACKBAR_DURATION);
    } catch (e) {
      debugPrint('Fehler beim Löschen des Eintrags: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _recalculateTotalAmount() {
    totalAmount = 0.0;
    try {
      if (selectedMonth == 'Alle') {
        for (final entries in monthlyEntries.values) {
          for (final entry in entries) {
            final amount = double.tryParse(entry['amount']!.replaceAll(',', '.').replaceAll('€', '').trim()) ?? 0.0;
            totalAmount += amount;
          }
        }
      } else {
        for (final entry in workEntries) {
          final amount = double.tryParse(entry['amount']!.replaceAll(',', '.').replaceAll('€', '').trim()) ?? 0.0;
          totalAmount += amount;
        }
      }
    } catch (e) {
      debugPrint('Fehler bei der Berechnung der Gesamtsumme: $e');
    }
  }

  // Methode zum Löschen aller Arbeitstage
  Future<void> deleteAllWorkDays() async {
    try {
      debugPrint('=== LÖSCHE ALLE ARBEITSTAGE ===');

      // Leere alle monatlichen Arbeitseinträge
      monthlyEntries.clear();

      // Aktualisiere die workEntries Liste (entferne nur Arbeitseinträge, behalte Urlaub)
      if (showVacationDays) {
        // Wenn Urlaubstage angezeigt werden, behalte nur diese
        workEntries.removeWhere((entry) => entry['type'] != 'vacation' && entry['time'] != 'Urlaub');
      } else {
        // Wenn keine Urlaubstage angezeigt werden, leere komplett
        workEntries.clear();
      }

      // Speichere die Änderungen
      await _saveSettings();

      // Berechne Gesamtsumme neu (sollte 0 sein für Arbeitstage)
      _recalculateTotalAmount();

      notifyListeners();

      debugPrint('Alle Arbeitstage wurden gelöscht');
      debugPrint('=== ARBEITSTAGE LÖSCHEN ABGESCHLOSSEN ===');

    } catch (e) {
      debugPrint('Fehler beim Löschen aller Arbeitstage: $e');
    }
  }

  // Methode zum Löschen aller Urlaubstage
  Future<void> deleteAllVacationDays() async {
    try {
      debugPrint('=== LÖSCHE ALLE URLAUBSTAGE ===');

      // Leere alle Urlaubstage
      vacationDays.clear();

      // Entferne Urlaubseinträge aus der workEntries Liste
      workEntries.removeWhere((entry) => entry['type'] == 'vacation' || entry['time'] == 'Urlaub');

      // Speichere die Änderungen
      await _saveSettings();

      // Berechne Gesamtsumme neu
      _recalculateTotalAmount();

      notifyListeners();

      debugPrint('Alle Urlaubstage wurden gelöscht');
      debugPrint('=== URLAUBSTAGE LÖSCHEN ABGESCHLOSSEN ===');

    } catch (e) {
      debugPrint('Fehler beim Löschen aller Urlaubstage: $e');
    }
  }

  // Öffentliche Methode für Berechnungen von außerhalb
  Future<double> calculateEarnings(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    final regularWage = double.tryParse(prefs.getString('hourlyWage')?.replaceAll(',', '.') ?? '0') ?? 0.0;
    final nightWage = double.tryParse(prefs.getString('nightHourlyWage')?.replaceAll(',', '.') ?? regularWage.toString()) ?? regularWage;
    final nightBonusEnabled = prefs.getBool('nightBonusEnabled') ?? false;
    final nightFrom = prefs.getString('nightBonusFrom') ?? '';
    final nightTo = prefs.getString('nightBonusTo') ?? '';

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      return 0.0;
    }

    if (nightBonusEnabled && nightFrom.isNotEmpty && nightTo.isNotEmpty) {
      return _calculateWithNightBonus(start, end, regularWage, nightWage, nightFrom, nightTo);
    } else {
      final totalHours = end.difference(start).inMinutes / 60.0;
      return totalHours * regularWage;
    }
  }

}