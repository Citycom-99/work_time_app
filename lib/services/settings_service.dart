import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _hourlyWageKey = 'hourlyWage';
  static const String _nightBonusEnabledKey = 'nightBonusEnabled';
  static const String _nightBonusFromKey = 'nightBonusFrom';
  static const String _nightBonusToKey = 'nightBonusTo';
  static const String _nightHourlyWageKey = 'nightHourlyWage';
  static const String _showVacationDaysKey = 'showVacationDays';

  String hourlyWage = '';
  bool nightBonusEnabled = false;
  String nightBonusFrom = '';
  String nightBonusTo = '';
  String nightHourlyWage = '';
  bool showVacationDays = false;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    hourlyWage = prefs.getString(_hourlyWageKey) ?? '';
    nightBonusEnabled = prefs.getBool(_nightBonusEnabledKey) ?? false;
    nightBonusFrom = prefs.getString(_nightBonusFromKey) ?? '';
    nightBonusTo = prefs.getString(_nightBonusToKey) ?? '';
    nightHourlyWage = prefs.getString(_nightHourlyWageKey) ?? '';
    showVacationDays = prefs.getBool(_showVacationDaysKey) ?? false;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_hourlyWageKey, hourlyWage);
    await prefs.setBool(_nightBonusEnabledKey, nightBonusEnabled);
    await prefs.setString(_nightBonusFromKey, nightBonusFrom);
    await prefs.setString(_nightBonusToKey, nightBonusTo);
    await prefs.setString(_nightHourlyWageKey, nightHourlyWage);
    await prefs.setBool(_showVacationDaysKey, showVacationDays);
  }

  bool isValidWage(String wage) {
    if (wage.isEmpty) return false;
    final parsedWage = double.tryParse(wage.replaceAll(',', '.'));
    return parsedWage != null && parsedWage > 0.0;
  }

  double getRegularWage() {
    return double.tryParse(hourlyWage.replaceAll(',', '.')) ?? 0.0;
  }

  double getNightWage() {
    return double.tryParse(nightHourlyWage.replaceAll(',', '.')) ?? getRegularWage();
  }
}