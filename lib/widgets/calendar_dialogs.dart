// lib/widgets/calendar_dialogs.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/WorkTimeController.dart';
import '../services/calendar_service.dart';

class CalendarDialogs {
  static void showAddEntryDialog(BuildContext context, DateTime day, WorkTimeController controller, Function setState) {
    bool isWorkDay = false;
    bool isVacationDay = false;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // Check for overnight work from previous day
    final previousDay = day.subtract(const Duration(days: 1));
    final isPreviousDayOvernight = CalendarService.checkPreviousDayOvernight(previousDay, controller);
    String? overnightHint;

    if (isPreviousDayOvernight && !CalendarService.hasDirectWorkEntry(day, controller)) {
      final prevWorkTime = CalendarService.getDetailedWorkTime(previousDay, controller);
      if (prevWorkTime != null) {
        final endHour = prevWorkTime['endHour']!;
        final endMinute = prevWorkTime['endMinute']!;
        overnightHint = 'Nachtarbeit vom Vortag bis ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} Uhr';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Eintrag hinzufügen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datum: ${DateFormat('dd.MM.yyyy').format(day)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  // Overnight work hint
                  if (overnightHint != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            color: Colors.purple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              overnightHint,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Arbeitstag Option - Jetzt mit oranger Hinterlegung
                  Container(
                    decoration: BoxDecoration(
                      color: isWorkDay
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWorkDay
                            ? Colors.orange.withOpacity(0.4)
                            : Colors.orange.withOpacity(0.2),
                        width: isWorkDay ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: isWorkDay ? Colors.orange[700] : Colors.orange[400],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Arbeitstag hinzufügen',
                              style: TextStyle(
                                fontWeight: isWorkDay ? FontWeight.w600 : FontWeight.normal,
                                color: isWorkDay ? Colors.orange[800] : Colors.orange[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      value: isWorkDay,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setDialogState(() {
                          isWorkDay = value ?? false;
                          if (isWorkDay) {
                            isVacationDay = false;
                          }
                        });
                      },
                    ),
                  ),

                  if (isWorkDay) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Startzeit
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (time != null) {
                                setDialogState(() => startTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: startTime != null ? Colors.green : Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: startTime != null ? Colors.green : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Start', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    startTime?.format(context) ?? '--:--',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: startTime != null ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Endzeit
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (time != null) {
                                setDialogState(() => endTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: endTime != null ? Colors.orange : Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_filled,
                                        color: endTime != null ? Colors.orange : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Ende', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    endTime?.format(context) ?? '--:--',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: endTime != null ? Colors.orange : Colors.grey,
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

                  const SizedBox(height: 16),

                  // Urlaub Option - Jetzt mit grüner Hinterlegung
                  Container(
                    decoration: BoxDecoration(
                      color: isVacationDay
                          ? Colors.green.withOpacity(0.15)
                          : Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVacationDay
                            ? Colors.green.withOpacity(0.4)
                            : Colors.green.withOpacity(0.2),
                        width: isVacationDay ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.beach_access,
                            color: isVacationDay ? Colors.green[700] : Colors.green[400],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Urlaub eintragen',
                              style: TextStyle(
                                fontWeight: isVacationDay ? FontWeight.w600 : FontWeight.normal,
                                color: isVacationDay ? Colors.green[800] : Colors.green[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      value: isVacationDay,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setDialogState(() {
                          isVacationDay = value ?? false;
                          if (isVacationDay) {
                            isWorkDay = false;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Roter X-Button
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.close),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isWorkDay && startTime != null && endTime != null) {
                            final dateString = DateFormat('dd.MM.yyyy').format(day);
                            if (controller.isVacationDay(dateString)) {
                              _showSnackBar(context, 'Arbeitstag überschneidet mit Urlaub', Colors.orange);
                              return;
                            }

                            await controller.addWorkEntryDirectly(context, day, startTime!, endTime!);
                            Navigator.of(context).pop();
                            setState();
                            _showSnackBar(context, 'Arbeitstag erfolgreich hinzugefügt', Colors.green);
                          } else if (isVacationDay) {
                            final dateString = DateFormat('dd.MM.yyyy').format(day);
                            if (CalendarService.hasWorkEntry(day, controller, CalendarView.month)) {
                              _showSnackBar(context, 'Urlaubstag überschneidet mit Arbeitstag', Colors.orange);
                              return;
                            }

                            await controller.addVacationDay(dateString);
                            Navigator.of(context).pop();
                            setState();
                            _showSnackBar(context, 'Urlaubstag erfolgreich hinzugefügt', Colors.green);
                          } else {
                            _showSnackBar(context, 'Bitte wählen Sie eine Option und füllen alle Felder aus', Colors.orange);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showWorkEntryDetails(BuildContext context, DateTime day, WorkTimeController controller, Function setState) {
    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    List<Map<String, String>> dayEntries = [];
    bool hasVacation = controller.isVacationDay(dayString);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      dayEntries = controller.monthlyEntries[monthKey]!
          .where((entry) => entry['date'] == dayString)
          .toList();
    }

    if (hasVacation) {
      dayEntries.add({
        'date': dayString,
        'time': 'Urlaub',
        'amount': '0,00',
        'type': 'vacation',
      });
    }

    // Check for overnight entries from previous day
    final previousDay = day.subtract(const Duration(days: 1));
    final isPreviousDayOvernight = CalendarService.checkPreviousDayOvernight(previousDay, controller);

    if (isPreviousDayOvernight && !CalendarService.hasDirectWorkEntry(day, controller)) {
      final prevWorkTime = CalendarService.getDetailedWorkTime(previousDay, controller);
      if (prevWorkTime != null) {
        final startHour = prevWorkTime['startHour']!;
        final startMinute = prevWorkTime['startMinute']!;
        final endHour = prevWorkTime['endHour']!;
        final endMinute = prevWorkTime['endMinute']!;

        final prevDayString = DateFormat('dd.MM.yyyy').format(previousDay);
        final prevMonthKey = DateFormat('yyyy-MM').format(previousDay);
        String amount = '0,00';

        if (controller.monthlyEntries.containsKey(prevMonthKey)) {
          final prevEntry = controller.monthlyEntries[prevMonthKey]!
              .firstWhere((entry) => entry['date'] == prevDayString,
              orElse: () => {'amount': '0,00'});
          amount = prevEntry['amount'] ?? '0,00';
        }

        dayEntries.add({
          'date': dayString,
          'time': '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
          'amount': amount,
          'type': 'overnight',
        });
      }
    }

    if (dayEntries.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datum: ${DateFormat('dd.MM.yyyy').format(day)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ...dayEntries.map((entry) {
                bool isVacation = entry['type'] == 'vacation';
                bool isOvernight = entry['type'] == 'overnight' || CalendarService.isOvernightWork(day, controller);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVacation
                        ? Colors.green.withOpacity(0.1)
                        : (isOvernight
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isVacation
                            ? Colors.green.withOpacity(0.3)
                            : (isOvernight
                            ? Colors.purple.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3))
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isVacation) ...[
                        const Text(
                          'Urlaubstag',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              'Arbeitszeit: ${entry['time']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (isOvernight) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.nightlight_round,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verdienst: ${entry['amount']}€',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        if (isOvernight) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry['type'] == 'overnight'
                                ? 'Fortsetzung einer Nachtschicht'
                                : 'Nachtschicht bis zum nächsten Tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDeleteConfirmation(context, day, dayEntries, controller, setState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.delete, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Schließen', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showDeleteConfirmation(BuildContext context, DateTime day, List<Map<String, String>> dayEntries, WorkTimeController controller, Function setState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Eintrag löschen',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Möchten Sie ${dayEntries.length > 1 ? 'alle Einträge' : 'den Eintrag'} vom ${DateFormat('dd.MM.yyyy').format(day)} wirklich löschen?',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Nein', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      CalendarService.deleteEntriesForDay(day, controller);
                      setState();
                      _showSnackBar(context,
                          '${dayEntries.length > 1 ? 'Alle Einträge' : 'Eintrag'} vom ${DateFormat('dd.MM.yyyy').format(day)} wurde${dayEntries.length > 1 ? 'n' : ''} gelöscht',
                          Colors.green
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ja', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}