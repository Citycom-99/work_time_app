// lib/utils/WorkTimeController.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/settings_service.dart';
import '../services/data_service.dart';
import '../services/calculation_service.dart';
import '../services/ui_service.dart';

class WorkTimeController extends ChangeNotifier {
  // Services
  final SettingsService _settingsService = SettingsService();
  final DataService _dataService = DataService();

  // UI State
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Map<String, String>> workEntries = [];
  double totalAmount = 0.0;

  // Getters für Settings (delegiert an SettingsService)
  String get hourlyWage => _settingsService.hourlyWage;
  set hourlyWage(String value) {
    _settingsService.hourlyWage = value;
    notifyListeners();
  }

  bool get nightBonusEnabled => _settingsService.nightBonusEnabled;
  set nightBonusEnabled(bool value) {
    _settingsService.nightBonusEnabled = value;
    notifyListeners();
  }

  String get nightBonusFrom => _settingsService.nightBonusFrom;
  set nightBonusFrom(String value) {
    _settingsService.nightBonusFrom = value;
    notifyListeners();
  }

  String get nightBonusTo => _settingsService.nightBonusTo;
  set nightBonusTo(String value) {
    _settingsService.nightBonusTo = value;
    notifyListeners();
  }

  String get nightHourlyWage => _settingsService.nightHourlyWage;
  set nightHourlyWage(String value) {
    _settingsService.nightHourlyWage = value;
    notifyListeners();
  }

  bool get showVacationDays => _settingsService.showVacationDays;
  set showVacationDays(bool value) {
    _settingsService.showVacationDays = value;
    notifyListeners();
  }

  // Getters für Data (delegiert an DataService)
  Map<String, List<Map<String, String>>> get monthlyEntries => _dataService.monthlyEntries;
  Map<String, List<String>> get vacationDays => _dataService.vacationDays;

  // === INITIALIZATION ===
  Future<void> loadSettings() async {
    try {
      await _settingsService.loadSettings();
      await _dataService.loadData();

      // Force update nach dem Laden
      selectedMonth = '';
      updateSelectedMonth('Alle');

      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Laden der Einstellungen: $e');
    }
  }

  Future<void> saveSettings() async {
    await _settingsService.saveSettings();
    await _dataService.saveData();
    notifyListeners();
  }

  // === MONTH SELECTION & FILTERING ===
  void updateSelectedMonth(String month) {
    selectedMonth = month;

    // Load work entries for selected month
    if (month == 'Alle') {
      workEntries = _dataService.monthlyEntries.values.expand((e) => e).toList();
    } else {
      workEntries = List<Map<String, String>>.from(_dataService.monthlyEntries[month] ?? []);
    }

    // Add vacation entries if enabled
    if (_settingsService.showVacationDays) {
      _addVacationEntriesToWorkEntries(month);
    }

    _dataService.sortEntriesByDate(workEntries);
    _recalculateTotalAmount();
    notifyListeners();
  }

  void _addVacationEntriesToWorkEntries(String month) {
    if (month == 'Alle') {
      for (var monthEntry in _dataService.vacationDays.entries) {
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
      if (_dataService.vacationDays.containsKey(month)) {
        for (String dayString in _dataService.vacationDays[month]!) {
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
    _settingsService.showVacationDays = !_settingsService.showVacationDays;
    saveSettings();

    // Force refresh
    String currentMonth = selectedMonth;
    selectedMonth = '';
    updateSelectedMonth(currentMonth);
  }

  // === WORK ENTRY MANAGEMENT ===
  Future<void> addWorkEntry(BuildContext context) async {
    try {
      if (!_settingsService.isValidWage(_settingsService.hourlyWage)) {
        UIService.showSnackBar(context, 'Bitte zuerst einen Stundenlohn festlegen',
            UIService.SNACKBAR_WARNING_COLOR, UIService.SNACKBAR_WARNING_DURATION);
        return;
      }

      final selectedDate = await UIService.selectDate(context, selectedMonth);
      if (selectedDate == null) return;

      // Check for vacation conflict
      final dateString = DateFormat('dd.MM.yyyy').format(selectedDate);
      if (_dataService.isVacationDay(dateString)) {
        UIService.showSnackBar(context, 'Arbeitstag überschneidet mit Urlaub',
            UIService.SNACKBAR_WARNING_COLOR, UIService.SNACKBAR_WARNING_DURATION);
        return;
      }

      final timeRange = await UIService.selectTimeRange(context);
      if (timeRange == null) return;

      final amount = await _calculateAmount(selectedDate, timeRange);
      await _saveWorkEntry(context, selectedDate, timeRange, amount);

    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Arbeitseintrags: $e');
    }
  }

  Future<void> addWorkEntryDirectly(BuildContext context, DateTime selectedDate, TimeOfDay startTime, TimeOfDay endTime) async {
    try {
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime.hour, startTime.minute);

      // Check if end time is next day (over midnight)
      DateTime end;
      if (endTime.hour < startTime.hour) {
        end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, endTime.hour, endTime.minute);
      } else {
        end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime.hour, endTime.minute);
      }

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        debugPrint('Error: End time is before or same as start time');
        return;
      }

      final amount = await CalculationService.calculateEarnings(
        start: start,
        end: end,
        regularWage: _settingsService.getRegularWage(),
        nightWage: _settingsService.getNightWage(),
        nightBonusEnabled: _settingsService.nightBonusEnabled,
        nightFrom: _settingsService.nightBonusFrom,
        nightTo: _settingsService.nightBonusTo,
      );

      // Format data
      String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);
      String formattedTime = '${startTime.format(context)} - ${endTime.format(context)}';
      String formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');

      // Save entry
      _dataService.addWorkEntry(formattedDate, formattedTime, formattedAmount);

      // Update current view if relevant
      String monthKey = DateFormat('yyyy-MM').format(selectedDate);
      if (selectedMonth == 'Alle' || selectedMonth == monthKey) {
        workEntries.add({
          'date': formattedDate,
          'time': formattedTime,
          'amount': formattedAmount,
        });
        _dataService.sortEntriesByDate(workEntries);
      }

      await saveSettings();
      _recalculateTotalAmount();
      notifyListeners();

    } catch (e) {
      debugPrint('Error adding work entry directly: $e');
    }
  }

  // === VACATION MANAGEMENT ===
  Future<void> addVacationDay(String dateString) async {
    _dataService.addVacationDay(dateString);
    await saveSettings();
    updateSelectedMonth(selectedMonth);
  }

  Future<void> removeVacationDay(String dateString) async {
    _dataService.removeVacationDay(dateString);
    await saveSettings();
  }

  bool isVacationDay(String dateString) {
    return _dataService.isVacationDay(dateString);
  }

  // === DELETION METHODS ===
  Future<void> deleteAllWorkDays() async {
    _dataService.deleteAllWorkDays();

    // Update workEntries (keep only vacation if shown)
    if (_settingsService.showVacationDays) {
      workEntries.removeWhere((entry) => entry['type'] != 'vacation' && entry['time'] != 'Urlaub');
    } else {
      workEntries.clear();
    }

    await saveSettings();
    _recalculateTotalAmount();
    notifyListeners();
  }

  Future<void> deleteAllVacationDays() async {
    _dataService.deleteAllVacationDays();
    workEntries.removeWhere((entry) => entry['type'] == 'vacation' || entry['time'] == 'Urlaub');

    await saveSettings();
    _recalculateTotalAmount();
    notifyListeners();
  }

  // === UI COMPONENTS ===
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
                    onTap: () => UIService.showDatePickerForEntry(context, entry, saveSettings),
                  ),
                  DataCell(
                    Text(entry['time']!.replaceAll(RegExp(r'\s+'), '').trim()),
                    onTap: () => UIService.showTimePickerForEntry(context, entry, saveSettings),
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

  // Settings Dialog - delegiert an UIService
  void openSettingsDialog(BuildContext context) {
    UIService.openSettingsDialog(context, _settingsService, () async {
      await saveSettings();
      notifyListeners();
    });
  }

  // === PRIVATE HELPER METHODS ===
  Future<double> _calculateAmount(DateTime selectedDate, Map<String, TimeOfDay> timeRange) async {
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        timeRange['start']!.hour, timeRange['start']!.minute);

    DateTime end;
    if (timeRange['end']!.hour < timeRange['start']!.hour) {
      end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1,
          timeRange['end']!.hour, timeRange['end']!.minute);
    } else {
      end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
          timeRange['end']!.hour, timeRange['end']!.minute);
    }

    return await CalculationService.calculateEarnings(
      start: start,
      end: end,
      regularWage: _settingsService.getRegularWage(),
      nightWage: _settingsService.getNightWage(),
      nightBonusEnabled: _settingsService.nightBonusEnabled,
      nightFrom: _settingsService.nightBonusFrom,
      nightTo: _settingsService.nightBonusTo,
    );
  }

  Future<void> _saveWorkEntry(BuildContext context, DateTime selectedDate, Map<String, TimeOfDay> timeRange, double amount) async {
    final formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);
    final formattedTime = '${timeRange['start']!.format(context)} - ${timeRange['end']!.format(context)}';
    final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');

    _dataService.addWorkEntry(formattedDate, formattedTime, formattedAmount);

    final monthKey = DateFormat('yyyy-MM').format(selectedDate);
    if (selectedMonth == 'Alle' || selectedMonth == monthKey) {
      workEntries.add({
        'date': formattedDate,
        'time': formattedTime,
        'amount': formattedAmount,
      });
      _dataService.sortEntriesByDate(workEntries);
    }

    await saveSettings();
    _recalculateTotalAmount();
    notifyListeners();
  }

  void _deleteWorkEntry(BuildContext context, int index) {
    if (workEntries.isEmpty || index < 0 || index >= workEntries.length) {
      return;
    }

    UIService.showDeleteConfirmation(context, 'Eintrag löschen', 'Möchten Sie den Eintrag wirklich löschen?')
        .then((confirmed) {
      if (confirmed) {
        _confirmDeleteWorkEntry(context, index);
      }
    });
  }

  void _confirmDeleteWorkEntry(BuildContext context, int index) {
    try {
      final entry = workEntries[index];
      final entryDate = entry['date']!;

      if (entry['type'] == 'vacation' || entry['time'] == 'Urlaub') {
        _dataService.removeVacationDay(entryDate);
      } else {
        _dataService.removeWorkEntry(entry['date']!, entry['time']!, entry['amount']!);
      }

      workEntries.removeAt(index);
      saveSettings();
      _recalculateTotalAmount();
      notifyListeners();

      UIService.showSnackBar(context, 'Eintrag wurde gelöscht',
          UIService.SNACKBAR_SUCCESS_COLOR, UIService.SNACKBAR_DURATION);
    } catch (e) {
      debugPrint('Fehler beim Löschen des Eintrags: $e');
    }
  }

  void _recalculateTotalAmount() {
    totalAmount = CalculationService.recalculateTotalAmount(
      selectedMonth,
      _dataService.monthlyEntries,
      workEntries,
    );
  }

  // === PUBLIC CALCULATION METHOD ===
  Future<double> calculateEarnings(DateTime start, DateTime end) async {
    return await CalculationService.calculateEarnings(
      start: start,
      end: end,
      regularWage: _settingsService.getRegularWage(),
      nightWage: _settingsService.getNightWage(),
      nightBonusEnabled: _settingsService.nightBonusEnabled,
      nightFrom: _settingsService.nightBonusFrom,
      nightTo: _settingsService.nightBonusTo,
    );
  }
}