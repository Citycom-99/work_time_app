// lib/services/calendar_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/WorkTimeController.dart';
import '../screens/calendar_page.dart';

enum CalendarView { month, week, day }

class CalendarService {
  // Date Helper Methods
  static List<DateTime> getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    List<DateTime> days = [];

    final firstWeekday = firstDay.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(1970, 1, 1));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    return days;
  }

  static String getViewTitle(CalendarView currentView, DateTime currentMonth, DateTime currentWeek, DateTime currentDay) {
    switch (currentView) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy', 'de_DE').format(currentMonth);
      case CalendarView.week:
        final startOfWeek = currentWeek.subtract(Duration(days: currentWeek.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd.MM', 'de_DE').format(startOfWeek)} - ${DateFormat('dd.MM.yyyy', 'de_DE').format(endOfWeek)}';
      case CalendarView.day:
        return DateFormat('dd.MM.yyyy', 'de_DE').format(currentDay);
    }
  }

  // Work Entry Checker Methods
  static bool hasWorkEntry(DateTime day, WorkTimeController controller, CalendarView currentView) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    bool hasNormalWork = false;
    if (controller.monthlyEntries.containsKey(monthKey)) {
      hasNormalWork = controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }

    if (currentView == CalendarView.week) {
      final previousDay = day.subtract(const Duration(days: 1));
      final hasOvernightFromPrevious = checkPreviousDayOvernight(previousDay, controller);
      return hasNormalWork || hasOvernightFromPrevious;
    }

    return hasNormalWork;
  }

  static bool hasWorkEntryMonthView(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      return controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }
    return false;
  }

  static bool checkPreviousDayOvernight(DateTime previousDay, WorkTimeController controller) {
    final prevDayString = DateFormat('dd.MM.yyyy').format(previousDay);
    final prevMonthKey = DateFormat('yyyy-MM').format(previousDay);

    if (controller.monthlyEntries.containsKey(prevMonthKey)) {
      final prevDayEntries = controller.monthlyEntries[prevMonthKey]!
          .where((entry) => entry['date'] == prevDayString)
          .toList();

      for (var entry in prevDayEntries) {
        final timeString = entry['time'] ?? '';
        if (timeString.contains(' - ')) {
          final timeParts = timeString.split(' - ');
          if (timeParts.length == 2) {
            try {
              final startParts = timeParts[0].split(':');
              final endParts = timeParts[1].split(':');

              final startHour = int.parse(startParts[0]);
              final endHour = int.parse(endParts[0]);

              if (endHour < startHour) {
                return true;
              }
            } catch (e) {
              debugPrint('Fehler beim Parsen der Vortags-Arbeitszeit: $e');
            }
          }
        }
      }
    }
    return false;
  }

  static bool isVacationDay(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    return controller.isVacationDay(dayString);
  }

  static bool isOvernightWork(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      final dayEntries = controller.monthlyEntries[monthKey]!
          .where((entry) => entry['date'] == dayString)
          .toList();

      for (var entry in dayEntries) {
        final timeString = entry['time'] ?? '';
        if (timeString.contains(' - ')) {
          final timeParts = timeString.split(' - ');
          if (timeParts.length == 2) {
            try {
              final startParts = timeParts[0].split(':');
              final endParts = timeParts[1].split(':');

              final startHour = int.parse(startParts[0]);
              final endHour = int.parse(endParts[0]);

              if (endHour < startHour) {
                return true;
              }
            } catch (e) {
              debugPrint('Fehler beim Parsen der Arbeitszeit: $e');
            }
          }
        }
      }
    }

    return false;
  }

  static bool hasDirectWorkEntry(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      return controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }
    return false;
  }

  static Map<String, int>? getDetailedWorkTime(DateTime day, WorkTimeController controller) {
    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      final dayEntries = controller.monthlyEntries[monthKey]!
          .where((entry) => entry['date'] == dayString)
          .toList();

      if (dayEntries.isNotEmpty) {
        final timeString = dayEntries.first['time'] ?? '';
        if (timeString.contains(' - ')) {
          final timeParts = timeString.split(' - ');
          if (timeParts.length == 2) {
            try {
              final startParts = timeParts[0].split(':');
              final startHour = int.parse(startParts[0]);
              final startMinute = int.parse(startParts[1]);

              final endParts = timeParts[1].split(':');
              final endHour = int.parse(endParts[0]);
              final endMinute = int.parse(endParts[1]);

              return {
                'startHour': startHour,
                'startMinute': startMinute,
                'endHour': endHour,
                'endMinute': endMinute,
              };
            } catch (e) {
              debugPrint('Fehler beim Parsen der Arbeitszeit: $e');
            }
          }
        }
      }
    }
    return null;
  }

  // Entry Management
  static void deleteEntriesForDay(DateTime day, WorkTimeController controller) {
    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    bool hasVacation = controller.isVacationDay(dayString);

    if (hasVacation) {
      controller.removeVacationDay(dayString);
    }

    if (controller.monthlyEntries.containsKey(monthKey)) {
      controller.monthlyEntries[monthKey]!.removeWhere((entry) => entry['date'] == dayString);

      if (controller.monthlyEntries[monthKey]!.isEmpty) {
        controller.monthlyEntries.remove(monthKey);
      }
    }

    controller.workEntries.removeWhere((entry) => entry['date'] == dayString);
    controller.notifyListeners();
  }
}