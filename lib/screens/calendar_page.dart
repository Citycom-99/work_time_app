import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_time_app/widgets/main_drawer.dart';
import 'package:intl/intl.dart';
import '../utils/WorkTimeController.dart';

// Enum für die verschiedenen Ansichten
enum CalendarView { month, week, day }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _currentWeek = DateTime.now();
  DateTime _currentDay = DateTime.now();

  // Variable für die aktuelle Ansicht
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _changeDate(int direction) {
    setState(() {
      switch (_currentView) {
        case CalendarView.month:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + direction, 1);
          break;
        case CalendarView.week:
          _currentWeek = _currentWeek.add(Duration(days: 7 * direction));
          break;
        case CalendarView.day:
          _currentDay = _currentDay.add(Duration(days: direction));
          break;
      }
    });
  }

  String _getViewTitle() {
    switch (_currentView) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy', 'de_DE').format(_currentMonth);
      case CalendarView.week:
        final startOfWeek = _currentWeek.subtract(Duration(days: _currentWeek.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd.MM', 'de_DE').format(startOfWeek)} - ${DateFormat('dd.MM.yyyy', 'de_DE').format(endOfWeek)}';
      case CalendarView.day:
        return DateFormat('dd.MM.yyyy', 'de_DE').format(_currentDay);
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
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

  // Erweiterte _hasWorkEntry Methode - nur für Wochenansicht mit Folgetag-Erkennung
  bool _hasWorkEntry(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    // Prüfe normale Arbeitseinträge für diesen Tag
    bool hasNormalWork = false;
    if (controller.monthlyEntries.containsKey(monthKey)) {
      hasNormalWork = controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }

    // Für die Wochenansicht: Prüfe auch Übernacht-Einträge vom Vortag
    // Für die Monatsansicht: Zeige Folgetage NICHT als Arbeitstage
    if (_currentView == CalendarView.week) {
      final previousDay = day.subtract(const Duration(days: 1));
      final hasOvernightFromPrevious = _checkPreviousDayOvernight(previousDay, controller);
      return hasNormalWork || hasOvernightFromPrevious;
    }

    // Monatsansicht: Nur direkte Arbeitseinträge
    return hasNormalWork;
  }

  // Separate Methode für Monatsansicht - nur direkte Einträge
  bool _hasWorkEntryMonthView(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      return controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }
    return false;
  }

  bool _checkPreviousDayOvernight(DateTime previousDay, WorkTimeController controller) {
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

              // Wenn Endstunde < Startstunde = Übernacht-Schicht
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

  bool _isVacationDay(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    return controller.isVacationDay(dayString);
  }

  bool _isOvernightWork(DateTime day, WorkTimeController controller) {
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

  String _getWorkTimeForDay(DateTime day, WorkTimeController controller) {
    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      final dayEntries = controller.monthlyEntries[monthKey]!
          .where((entry) => entry['date'] == dayString)
          .toList();

      if (dayEntries.isNotEmpty) {
        final time = dayEntries.first['time'] ?? '';
        return time.replaceAll(' - ', '-');
      }
    }
    return '';
  }

  void _showAddEntryDialog(DateTime day, WorkTimeController controller) {
    bool isWorkDay = false;
    bool isVacationDay = false;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text('Arbeitstag hinzufügen'),
                    value: isWorkDay,
                    onChanged: (value) {
                      setState(() {
                        isWorkDay = value ?? false;
                        if (isWorkDay) {
                          isVacationDay = false;
                        }
                      });
                    },
                  ),
                  if (isWorkDay) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  startTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                startTime != null
                                    ? 'Start: ${startTime!.format(context)}'
                                    : 'Startzeit wählen',
                                style: TextStyle(
                                  color: startTime != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (time != null) {
                                setState(() {
                                  endTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                endTime != null
                                    ? 'Ende: ${endTime!.format(context)}'
                                    : 'Endzeit wählen',
                                style: TextStyle(
                                  color: endTime != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  CheckboxListTile(
                    title: const Text('Urlaub eintragen'),
                    value: isVacationDay,
                    onChanged: (value) {
                      setState(() {
                        isVacationDay = value ?? false;
                        if (isVacationDay) {
                          isWorkDay = false;
                        }
                      });
                    },
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
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isWorkDay && startTime != null && endTime != null) {
                            final dateString = DateFormat('dd.MM.yyyy').format(day);
                            if (controller.isVacationDay(dateString)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Arbeitstag überschneidet mit Urlaub'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            await controller.addWorkEntryDirectly(context, day, startTime!, endTime!);
                            Navigator.of(context).pop();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Arbeitstag erfolgreich hinzugefügt'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else if (isVacationDay) {
                            final dateString = DateFormat('dd.MM.yyyy').format(day);
                            if (_hasWorkEntry(day, controller)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Urlaubstag überschneidet mit Arbeitstag'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            await controller.addVacationDay(dateString);
                            Navigator.of(context).pop();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Urlaubstag erfolgreich hinzugefügt'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bitte eine Option auswählen und alle Felder ausfüllen'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        child: const Text(
                          'Hinzufügen',
                          style: TextStyle(fontSize: 12),
                        ),
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

  void _showWorkEntryDetails(DateTime day, WorkTimeController controller) {
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

    // Prüfe auch Übernacht-Einträge vom Vortag
    final previousDay = day.subtract(const Duration(days: 1));
    final isPreviousDayOvernight = _checkPreviousDayOvernight(previousDay, controller);

    if (isPreviousDayOvernight && !_hasDirectWorkEntry(day, controller)) {
      // Füge den Folgetag-Eintrag hinzu
      final prevWorkTime = _getDetailedWorkTime(previousDay, controller);
      if (prevWorkTime != null) {
        final startHour = prevWorkTime['startHour']!;
        final startMinute = prevWorkTime['startMinute']!;
        final endHour = prevWorkTime['endHour']!;
        final endMinute = prevWorkTime['endMinute']!;

        // Berechne den Verdienst für diesen Tag (müsste vom Controller kommen)
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
                bool isOvernight = entry['type'] == 'overnight' || _isOvernightWork(day, controller);

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
                        // Arbeitszeit mit optionalem Übernacht-Indikator
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
                        // Zusätzlicher Hinweis bei Übernacht-Arbeit
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
                      _showDeleteConfirmation(day, dayEntries, controller);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Icon(Icons.delete, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Schließen',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(DateTime day, List<Map<String, String>> dayEntries, WorkTimeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: const Color(0xFFFFFFFF),
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteEntriesForDay(day, dayEntries, controller);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: const Color(0xFFFFFFFF),
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
    );
  }

  void _deleteEntriesForDay(DateTime day, List<Map<String, String>> dayEntries, WorkTimeController controller) {
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

    setState(() {});
    controller.notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${dayEntries.length > 1 ? 'Alle Einträge' : 'Eintrag'} vom ${DateFormat('dd.MM.yyyy').format(day)} wurde${dayEntries.length > 1 ? 'n' : ''} gelöscht'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Angepasste _buildCalendarDay Methode für Monatsansicht
  Widget _buildCalendarDay(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) {
      return Container();
    }

    final isToday = DateFormat('dd.MM.yyyy').format(day) ==
        DateFormat('dd.MM.yyyy').format(DateTime.now());
    final hasWork = _hasWorkEntryMonthView(day, controller); // Verwende spezielle Monatsansicht-Methode
    final isVacation = _isVacationDay(day, controller);
    final isOvernight = _isOvernightWork(day, controller);

    Color backgroundColor = Colors.transparent;
    Color textColor = isToday ? Colors.blue : Colors.black;

    if (isVacation) {
      backgroundColor = Colors.green.withOpacity(0.7);
      textColor = Colors.white;
    } else if (hasWork) {
      backgroundColor = isOvernight
          ? Colors.purple.withOpacity(0.7)  // Lila nur für den Starttag
          : Colors.orange.withOpacity(0.7); // Orange für normale Arbeit
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.blue.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () {
        // Für Details: Prüfe auch Folgetage von Übernacht-Schichten
        final previousDay = day.subtract(const Duration(days: 1));
        final isPreviousDayOvernight = _checkPreviousDayOvernight(previousDay, controller);

        if (hasWork || isVacation || (isPreviousDayOvernight && !_hasWorkEntryMonthView(day, controller))) {
          _showWorkEntryDetails(day, controller);
        } else {
          _showAddEntryDialog(day, controller);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isToday
                ? Colors.blue
                : Colors.grey.withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            // Übernacht-Indikator nur für den Starttag
            if (isOvernight && hasWork)
              Positioned(
                top: 1,
                right: 1,
                child: const Icon(
                  Icons.nightlight_round,
                  color: Colors.yellow,
                  size: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month, WorkTimeController controller) {
    final days = _getDaysInMonth(month);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                .map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                return _buildCalendarDay(days[index], controller);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Wochenansicht
  Widget _buildWeekView(DateTime week, WorkTimeController controller) {
    final startOfWeek = week.subtract(Duration(days: week.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                .map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ),
        Expanded(
          child: Row(
            children: weekDays.map((day) => Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                child: _buildWeekDayColumn(day, controller),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayColumn(DateTime day, WorkTimeController controller) {
    final isToday = DateFormat('dd.MM.yyyy').format(day) ==
        DateFormat('dd.MM.yyyy').format(DateTime.now());
    final hasWork = _hasWorkEntry(day, controller);
    final isVacation = _isVacationDay(day, controller);
    final isOvernight = _isOvernightWork(day, controller);

    Color borderColor = isToday ? Colors.blue : Colors.grey.withOpacity(0.3);

    return GestureDetector(
      onTap: () {
        if (hasWork || isVacation) {
          _showWorkEntryDetails(day, controller);
        } else {
          _showAddEntryDialog(day, controller);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: isToday ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Datum Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : Colors.black,
                ),
              ),
            ),
            // 24-Stunden Zeitbereich
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;

                    return Stack(
                      children: [
                        // Stundenlinien (alle 1 Stunde)
                        ...List.generate(23, (index) {
                          double position = (index + 1) / 24; // 1h, 2h, 3h, ..., 23h
                          return Positioned(
                            top: position * availableHeight,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 0.3,
                              color: Colors.grey.withOpacity(0.15),
                            ),
                          );
                        }),

                        // Uhrzeiten-Labels (0, 6, 12, 18, 24 Uhr)
                        ...List.generate(5, (index) {
                          final hours = [0, 6, 12, 18, 24];
                          final hour = hours[index];
                          double position = hour / 24.0;

                          // Spezielle Positionierung für Anfang und Ende
                          if (hour == 0) {
                            position = 0.05; // 00:00 etwas nach unten
                          } else if (hour == 24) {
                            position = 0.95; // 24:00 etwas nach oben
                          }

                          return Positioned(
                            top: position * availableHeight - 6, // -6 für Zentrierung
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
                              ),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  fontSize: 7,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),

                        // Urlaub (ganzer Tag)
                        if (isVacation)
                          Positioned(
                            top: 0,
                            left: 2,
                            right: 2,
                            height: availableHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    'Urlaub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Arbeitszeit-Balken (proportional) - kommt NACH den Labels, überdeckt sie
                        if (hasWork && !isVacation)
                          _buildWorkTimeBar(day, controller, isOvernight, availableHeight),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTimeBar(DateTime day, WorkTimeController controller, bool isOvernight, double availableHeight) {
    // Prüfe zuerst ob dies ein "Folgetag" einer Übernacht-Schicht ist
    final previousDay = day.subtract(const Duration(days: 1));
    final isPreviousDayOvernight = _checkPreviousDayOvernight(previousDay, controller);

    if (isPreviousDayOvernight && !_hasDirectWorkEntry(day, controller)) {
      // Dies ist der Folgetag einer Übernacht-Schicht
      final prevWorkTime = _getDetailedWorkTime(previousDay, controller);
      if (prevWorkTime != null) {
        final endHour = prevWorkTime['endHour']!;
        final endMinute = prevWorkTime['endMinute']!;

        // Zeige den "nächster Tag" Teil der Übernacht-Schicht OHNE TEXT
        double endPercent = (endHour + endMinute / 60.0) / 24.0;

        return _buildSingleWorkBar(
          startPercent: 0.0, // Von Mitternacht
          endPercent: endPercent,
          isOvernight: true,
          timeText: '', // KEIN TEXT im Folgetag
          availableHeight: availableHeight,
        );
      }
    }

    // Normale Arbeitszeit oder Starttag einer Übernacht-Schicht
    final workTime = _getDetailedWorkTime(day, controller);
    if (workTime == null) return Container();

    final startHour = workTime['startHour']!;
    final startMinute = workTime['startMinute']!;
    final endHour = workTime['endHour']!;
    final endMinute = workTime['endMinute']!;

    double startPercent = (startHour + startMinute / 60.0) / 24.0;
    double endPercent = (endHour + endMinute / 60.0) / 24.0;

    if (isOvernight && endPercent < startPercent) {
      // Übernacht-Schicht: Zeige KOMPLETTE Zeit (Start bis tatsächliches Ende)
      return _buildSingleWorkBar(
        startPercent: startPercent,
        endPercent: 1.0, // Bis Mitternacht (visuell)
        isOvernight: true,
        timeText: '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}', // KOMPLETTE Zeit
        availableHeight: availableHeight,
      );
    } else {
      // Normale Arbeitszeit am gleichen Tag
      return _buildSingleWorkBar(
        startPercent: startPercent,
        endPercent: endPercent,
        isOvernight: false,
        timeText: '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
        availableHeight: availableHeight,
      );
    }
  }

  // Hilfsmethode um zu prüfen ob ein Tag direkte Arbeitseinträge hat (nicht vom Vortag)
  bool _hasDirectWorkEntry(DateTime day, WorkTimeController controller) {
    if (day.year == 1970) return false;

    final dayString = DateFormat('dd.MM.yyyy').format(day);
    final monthKey = DateFormat('yyyy-MM').format(day);

    if (controller.monthlyEntries.containsKey(monthKey)) {
      return controller.monthlyEntries[monthKey]!
          .any((entry) => entry['date'] == dayString);
    }
    return false;
  }

  bool _hasOvernightWorkEndingToday(DateTime previousDay, DateTime currentDay, WorkTimeController controller) {
    final previousWorkTime = _getDetailedWorkTime(previousDay, controller);
    if (previousWorkTime == null) return false;

    final startHour = previousWorkTime['startHour']!;
    final endHour = previousWorkTime['endHour']!;

    // Prüfe ob es eine Übernacht-Schicht ist (endHour < startHour)
    if (endHour < startHour) {
      // Prüfe ob die Endzeit zu diesem aktuellen Tag gehört
      final currentWorkTime = _getDetailedWorkTime(currentDay, controller);
      if (currentWorkTime != null) {
        final currentEndHour = currentWorkTime['endHour']!;
        final currentEndMinute = currentWorkTime['endMinute']!;

        // Wenn der aktuelle Tag die gleiche Endzeit hat wie der vorherige Tag
        // und die Endzeit früh am Tag ist, dann ist es der zweite Teil
        return currentEndHour == endHour &&
            currentWorkTime['endMinute'] == previousWorkTime['endMinute'] &&
            currentEndHour < 12; // Endzeit vor Mittag = wahrscheinlich Übernacht-Ende
      }
    }
    return false;
  }

  Widget _buildSingleWorkBar({
    required double startPercent,
    required double endPercent,
    required bool isOvernight,
    required String timeText,
    required double availableHeight,
  }) {
    final topPosition = startPercent * availableHeight;
    final barHeight = (endPercent - startPercent) * availableHeight;

    return Positioned(
      top: topPosition,
      left: 2,
      right: 2,
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          color: isOvernight
              ? Colors.purple.withOpacity(0.8)
              : Colors.orange.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Hauptinhalt - vertikaler Text (nur wenn Text vorhanden)
            if (timeText.isNotEmpty)
              Center(
                child: RotatedBox(
                  quarterTurns: 3, // 90° Drehung für vertikalen Text
                  child: Text(
                    timeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // Übernacht-Indikator
            if (isOvernight)
              Positioned(
                top: 2,
                right: 2,
                child: const Icon(
                  Icons.nightlight_round,
                  color: Colors.yellow,
                  size: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, int>? _getDetailedWorkTime(DateTime day, WorkTimeController controller) {
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
              // Parse Startzeit
              final startParts = timeParts[0].split(':');
              final startHour = int.parse(startParts[0]);
              final startMinute = int.parse(startParts[1]);

              // Parse Endzeit
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

  // Tagesansicht
  Widget _buildDayView(DateTime day, WorkTimeController controller) {
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(day),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: dayEntries.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Einträge für diesen Tag',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showAddEntryDialog(day, controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Eintrag hinzufügen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: dayEntries.length,
            itemBuilder: (context, index) {
              final entry = dayEntries[index];
              final isVacation = entry['type'] == 'vacation';
              final isOvernight = !isVacation && _isOvernightWork(day, controller);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isVacation
                      ? Colors.green.withOpacity(0.1)
                      : (isOvernight
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isVacation
                          ? Colors.green.withOpacity(0.3)
                          : (isOvernight
                          ? Colors.purple.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3))
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVacation ? Icons.beach_access : Icons.work,
                      color: isVacation
                          ? Colors.green
                          : (isOvernight ? Colors.purple : Colors.blue),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isVacation) ...[
                            const Text(
                              'Urlaubstag',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Text(
                                  'Arbeitszeit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isOvernight) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.nightlight_round,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const Text(
                                    'Übernacht',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              entry['time']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verdienst: ${entry['amount']}€',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(day, [entry], controller),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentView(WorkTimeController controller) {
    switch (_currentView) {
      case CalendarView.month:
        return _buildCalendarGrid(_currentMonth, controller);
      case CalendarView.week:
        return _buildWeekView(_currentWeek, controller);
      case CalendarView.day:
        return _buildDayView(_currentDay, controller);
    }
  }

  Widget _buildViewButton(CalendarView view, IconData icon, String tooltip) {
    final isSelected = _currentView == view;
    return Tooltip(
      message: tooltip == 'M' ? 'Monat' : tooltip == 'W' ? 'Woche' : 'Tag',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentView = view;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Kalender'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // View Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewButton(CalendarView.month, Icons.calendar_month, 'M'),
                _buildViewButton(CalendarView.week, Icons.view_week, 'W'),
                _buildViewButton(CalendarView.day, Icons.today, 'T'),
              ],
            ),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Consumer<WorkTimeController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Navigation Header
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.blue.withOpacity(0.1),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                      onPressed: () => _changeDate(-1),
                    ),
                    Text(
                      _getViewTitle(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                      onPressed: () => _changeDate(1),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      _changeDate(-1);
                    } else if (details.primaryVelocity! < 0) {
                      _changeDate(1);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentView(controller),
                  ),
                ),
              ),
              // Legend (nur bei Monats- und Wochenansicht)
              if (_currentView != CalendarView.day)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Arbeitstag'),
                          const SizedBox(width: 16),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: const Icon(
                                    Icons.nightlight_round,
                                    color: Colors.yellow,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Übernacht'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Urlaub'),
                          const SizedBox(width: 16),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Heute'),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}