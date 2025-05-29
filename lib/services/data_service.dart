import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DataService {
  static const String _monthlyEntriesKey = 'monthlyEntries';
  static const String _vacationDaysKey = 'vacationDays';

  Map<String, List<Map<String, String>>> monthlyEntries = {};
  Map<String, List<String>> vacationDays = {};

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadMonthlyEntries(prefs);
    await _loadVacationDays(prefs);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save monthly entries
    List<String> encodedMonthlyData = monthlyEntries.entries.map((e) {
      return json.encode({
        'month': e.key,
        'entries': e.value,
      });
    }).toList();

    // Save vacation days
    List<String> encodedVacationData = vacationDays.entries.map((e) {
      return json.encode({
        'month': e.key,
        'days': e.value,
      });
    }).toList();

    await prefs.setStringList(_monthlyEntriesKey, encodedMonthlyData);
    await prefs.setStringList(_vacationDaysKey, encodedVacationData);
  }

  Future<void> _loadMonthlyEntries(SharedPreferences prefs) async {
    List<String>? savedMonthlyData = prefs.getStringList(_monthlyEntriesKey);
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

  Future<void> _loadVacationDays(SharedPreferences prefs) async {
    List<String>? savedVacationData = prefs.getStringList(_vacationDaysKey);
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

  void addWorkEntry(String date, String time, String amount) {
    try {
      final dateObj = DateFormat('dd.MM.yyyy').parse(date);
      final monthKey = DateFormat('yyyy-MM').format(dateObj);

      monthlyEntries.putIfAbsent(monthKey, () => []);
      monthlyEntries[monthKey]!.add({
        'date': date,
        'time': time,
        'amount': amount,
      });

      sortEntriesByDate(monthlyEntries[monthKey]!);
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Arbeitseintrags: $e');
    }
  }

  void addVacationDay(String dateString) {
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
      }
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Urlaubstags: $e');
    }
  }

  void removeVacationDay(String dateString) {
    try {
      final date = DateFormat('dd.MM.yyyy').parse(dateString);
      final monthKey = DateFormat('yyyy-MM').format(date);

      if (vacationDays.containsKey(monthKey)) {
        vacationDays[monthKey]!.remove(dateString);
        if (vacationDays[monthKey]!.isEmpty) {
          vacationDays.remove(monthKey);
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Entfernen des Urlaubstags: $e');
    }
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

  void sortEntriesByDate(List<Map<String, String>> entries) {
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

  void deleteAllWorkDays() {
    monthlyEntries.clear();
  }

  void deleteAllVacationDays() {
    vacationDays.clear();
  }

  void removeWorkEntry(String date, String time, String amount) {
    try {
      final dateObj = DateFormat('dd.MM.yyyy').parse(date);
      final monthKey = DateFormat('yyyy-MM').format(dateObj);

      monthlyEntries[monthKey]?.removeWhere((e) =>
      e['date'] == date && e['time'] == time && e['amount'] == amount);

      if (monthlyEntries[monthKey]?.isEmpty == true) {
        monthlyEntries.remove(monthKey);
      }
    } catch (e) {
      debugPrint('Fehler beim Entfernen des Arbeitseintrags: $e');
    }
  }
}