import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalculationService {
  static Future<double> calculateEarnings({
    required DateTime start,
    required DateTime end,
    required double regularWage,
    required double nightWage,
    required bool nightBonusEnabled,
    required String nightFrom,
    required String nightTo,
  }) async {
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

  static double _calculateWithNightBonus(DateTime start, DateTime end, double regularWage,
      double nightWage, String nightFrom, String nightTo) {

    final nightStartHour = int.tryParse(nightFrom) ?? 22;
    final nightEndHour = int.tryParse(nightTo) ?? 6;

    debugPrint('=== NACHTZUSCHLAG BERECHNUNG ===');
    debugPrint('Arbeitszeit: ${DateFormat('dd.MM.yyyy HH:mm').format(start)} bis ${DateFormat('dd.MM.yyyy HH:mm').format(end)}');
    debugPrint('Nachtstunden: ${nightStartHour}:00 bis ${nightEndHour}:00');
    debugPrint('Regulärer Lohn: ${regularWage}€/h, Nacht-Lohn: ${nightWage}€/h');

    double totalAmount = 0.0;
    DateTime current = start;

    while (current.isBefore(end)) {
      DateTime nextHour = DateTime(current.year, current.month, current.day, current.hour + 1, 0);
      DateTime actualNext = nextHour.isAfter(end) ? end : nextHour;

      double minutesWorked = actualNext.difference(current).inMinutes.toDouble();
      double hoursWorked = minutesWorked / 60.0;

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

  static bool _isNightHour(int hour, int nightStart, int nightEnd) {
    if (nightStart < nightEnd) {
      return hour >= nightStart && hour < nightEnd;
    } else {
      return hour >= nightStart || hour < nightEnd;
    }
  }

  static double calculateTotalAmount(List<Map<String, String>> entries) {
    double total = 0.0;
    for (final entry in entries) {
      final amount = double.tryParse(entry['amount']!.replaceAll(',', '.').replaceAll('€', '').trim()) ?? 0.0;
      total += amount;
    }
    return total;
  }

  // Recalculate total for specific month or all months
  static double recalculateTotalAmount(
      String selectedMonth,
      Map<String, List<Map<String, String>>> monthlyEntries,
      List<Map<String, String>> workEntries
      ) {
    if (selectedMonth == 'Alle') {
      double total = 0.0;
      for (final entries in monthlyEntries.values) {
        total += calculateTotalAmount(entries);
      }
      return total;
    } else {
      // Only work entries (excluding vacation)
      final workOnlyEntries = workEntries.where((entry) =>
      entry['type'] != 'vacation' && entry['time'] != 'Urlaub'
      ).toList();
      return calculateTotalAmount(workOnlyEntries);
    }
  }
}