// lib/services/ui_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'settings_service.dart';

class UIService {
  static const Duration SNACKBAR_DURATION = Duration(seconds: 2);
  static const Duration SNACKBAR_WARNING_DURATION = Duration(seconds: 3);
  static const Color SNACKBAR_SUCCESS_COLOR = Colors.green;
  static const Color SNACKBAR_WARNING_COLOR = Colors.orange;
  static const TimeOfDay DEFAULT_START_TIME = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay DEFAULT_END_TIME = TimeOfDay(hour: 17, minute: 0);

  // Settings Dialog
  static void openSettingsDialog(BuildContext context, SettingsService settingsService, Function onSave) {
    final controller = TextEditingController(text: settingsService.hourlyWage);
    final nightWageController = TextEditingController(text: settingsService.nightHourlyWage);
    final fromController = TextEditingController(text: settingsService.nightBonusFrom);
    final toController = TextEditingController(text: settingsService.nightBonusTo);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Einstellungen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stundenlohn Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Stundenlohn',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'z.B. 15,50',
                                  prefixIcon: const Icon(Icons.euro, color: Colors.blue),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Nachtzuschlag Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: settingsService.nightBonusEnabled
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: settingsService.nightBonusEnabled
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nachtzuschlag Header
                              Row(
                                children: [
                                  Icon(
                                    Icons.nightlight_round,
                                    color: settingsService.nightBonusEnabled
                                        ? Colors.purple
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Nachtzuschlag',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: settingsService.nightBonusEnabled
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Switch in eigener Reihe
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Switch(
                                    value: settingsService.nightBonusEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        settingsService.nightBonusEnabled = value;
                                      });
                                    },
                                    activeColor: Colors.purple,
                                  ),
                                ),
                              ),

                              // Nachtzuschlag Details
                              if (settingsService.nightBonusEnabled) ...[
                                const SizedBox(height: 20),

                                // Nacht-Stundenlohn Label
                                const Text(
                                  'Nacht-Stundenlohn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Nacht-Stundenlohn Input
                                TextField(
                                  controller: nightWageController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'z.B. 20,00',
                                    prefixIcon: const Icon(Icons.euro, color: Colors.purple),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.purple, width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Zeitraum Label
                                const Text(
                                  'Zeitraum',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    // Von Zeit
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: ctx,
                                            initialTime: const TimeOfDay(hour: 22, minute: 0),
                                          );
                                          if (time != null) {
                                            fromController.text = time.hour.toString();
                                            setState(() {});
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.purple.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Colors.purple,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Von',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                fromController.text.isEmpty
                                                    ? '--:--'
                                                    : '${fromController.text}:00',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Bis Zeit
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: ctx,
                                            initialTime: const TimeOfDay(hour: 6, minute: 0),
                                          );
                                          if (time != null) {
                                            toController.text = time.hour.toString();
                                            setState(() {});
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.purple.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_filled,
                                                    color: Colors.purple,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Bis',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                toController.text.isEmpty
                                                    ? '--:--'
                                                    : '${toController.text}:00',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info Text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Für erweiterte Einstellungen öffne die Einstellungsseite über das Menü.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Icon(Icons.close, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            settingsService.hourlyWage = controller.text;
                            settingsService.nightHourlyWage = nightWageController.text;
                            settingsService.nightBonusFrom = fromController.text;
                            settingsService.nightBonusTo = toController.text;

                            await onSave();
                            Navigator.of(ctx).pop();

                            // Success feedback
                            showSnackBar(context, 'Einstellungen gespeichert', SNACKBAR_SUCCESS_COLOR, SNACKBAR_DURATION);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Icon(Icons.save, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Date Picker Helper
  static Future<DateTime?> selectDate(BuildContext context, String selectedMonth) async {
    DateTime initialDate;

    if (selectedMonth == 'Alle') {
      initialDate = DateTime.now();
    } else {
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

  // Time Range Picker Helper
  static Future<Map<String, TimeOfDay>?> selectTimeRange(BuildContext context) async {
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

  // Data Table Date Picker
  static Future<void> showDatePickerForEntry(BuildContext context, Map<String, String> entry, Function onSave) async {
    try {
      DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateFormat('dd.MM.yyyy').parse(entry['date']!),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (selectedDate != null) {
        entry['date'] = DateFormat('dd.MM.yyyy').format(selectedDate);
        await onSave();
      }
    } catch (e) {
      debugPrint('Fehler beim Datum-Picker: $e');
    }
  }

  // Data Table Time Picker
  static Future<void> showTimePickerForEntry(BuildContext context, Map<String, String> entry, Function onSave) async {
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
          await onSave();
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Zeit-Picker: $e');
    }
  }

  // Delete Confirmation Dialog
  static Future<bool> showDeleteConfirmation(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Nein'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ja'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // SnackBar Helper
  static void showSnackBar(BuildContext context, String message, Color backgroundColor, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}