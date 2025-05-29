// lib/widgets/calendar_views.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/WorkTimeController.dart';
import '../services/calendar_service.dart';
import 'calendar_dialogs.dart';

class CalendarViews {
  // MONTH VIEW
  static Widget buildCalendarGrid(DateTime month, WorkTimeController controller, Function setState) {
    final days = CalendarService.getDaysInMonth(month);

    return Column(
      children: [
        // Weekday Headers
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
        // Calendar Grid
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
                return _buildCalendarDay(days[index], controller, setState);
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildCalendarDay(DateTime day, WorkTimeController controller, Function setState) {
    if (day.year == 1970) return Container();

    final isToday = DateFormat('dd.MM.yyyy').format(day) ==
        DateFormat('dd.MM.yyyy').format(DateTime.now());
    final hasWork = CalendarService.hasWorkEntryMonthView(day, controller);
    final isVacation = CalendarService.isVacationDay(day, controller);
    final isOvernight = CalendarService.isOvernightWork(day, controller);

    Color backgroundColor = Colors.transparent;
    Color textColor = isToday ? Colors.blue : Colors.black;

    if (isVacation) {
      backgroundColor = Colors.green.withOpacity(0.7);
      textColor = Colors.white;
    } else if (hasWork) {
      backgroundColor = isOvernight
          ? Colors.purple.withOpacity(0.7)
          : Colors.orange.withOpacity(0.7);
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.blue.withOpacity(0.3);
    }

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // Immer den Add-Dialog zeigen, auch wenn es Übernacht-Einträge vom Vortag gibt
          // Der Details-Dialog wird nur gezeigt wenn es DIREKTE Einträge für diesen Tag gibt
          if (hasWork || isVacation) {
            CalendarDialogs.showWorkEntryDetails(context, day, controller, setState);
          } else {
            // Auch bei Folgetagen von Nachtschichten soll man neue Einträge hinzufügen können
            CalendarDialogs.showAddEntryDialog(context, day, controller, setState);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: isToday ? Colors.blue : Colors.grey.withOpacity(0.3),
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
      ),
    );
  }

  // WEEK VIEW
  static Widget buildWeekView(DateTime week, WorkTimeController controller, Function setState) {
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
                child: _buildWeekDayColumn(day, controller, setState),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  static Widget _buildWeekDayColumn(DateTime day, WorkTimeController controller, Function setState) {
    final isToday = DateFormat('dd.MM.yyyy').format(day) ==
        DateFormat('dd.MM.yyyy').format(DateTime.now());
    final hasWork = CalendarService.hasWorkEntry(day, controller, CalendarView.week);
    final isVacation = CalendarService.isVacationDay(day, controller);
    final isOvernight = CalendarService.isOvernightWork(day, controller);

    Color borderColor = isToday ? Colors.blue : Colors.grey.withOpacity(0.3);

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // Bei direkten Einträgen (Arbeit oder Urlaub) → Details zeigen
          // Bei leeren Tagen → Add Dialog zeigen (auch wenn Nachtschicht vom Vortag reinreicht)
          if (hasWork || isVacation) {
            CalendarDialogs.showWorkEntryDetails(context, day, controller, setState);
          } else {
            CalendarDialogs.showAddEntryDialog(context, day, controller, setState);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: isToday ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Date Header
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
              // 24-Hour Timeline
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
                          // Time grid lines and labels
                          ..._buildTimeGridLines(availableHeight),

                          // Vacation (full day)
                          if (isVacation)
                            _buildVacationBar(availableHeight),

                          // Work time bars
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
      ),
    );
  }

  static List<Widget> _buildTimeGridLines(double availableHeight) {
    return [
      // Hour lines
      ...List.generate(23, (index) {
        double position = (index + 1) / 24;
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

      // Time labels
      ...List.generate(5, (index) {
        final hours = [0, 6, 12, 18, 24];
        final hour = hours[index];
        double position = hour / 24.0;

        if (hour == 0) {
          position = 0.05;
        } else if (hour == 24) {
          position = 0.95;
        }

        return Positioned(
          top: position * availableHeight - 6,
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
    ];
  }

  static Widget _buildVacationBar(double availableHeight) {
    return Positioned(
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
    );
  }

  static Widget _buildWorkTimeBar(DateTime day, WorkTimeController controller, bool isOvernight, double availableHeight) {
    // Check if this is a continuation of overnight work
    final previousDay = day.subtract(const Duration(days: 1));
    final isPreviousDayOvernight = CalendarService.checkPreviousDayOvernight(previousDay, controller);

    if (isPreviousDayOvernight && !CalendarService.hasDirectWorkEntry(day, controller)) {
      final prevWorkTime = CalendarService.getDetailedWorkTime(previousDay, controller);
      if (prevWorkTime != null) {
        final endHour = prevWorkTime['endHour']!;
        final endMinute = prevWorkTime['endMinute']!;
        double endPercent = (endHour + endMinute / 60.0) / 24.0;

        return _buildSingleWorkBar(
          startPercent: 0.0,
          endPercent: endPercent,
          isOvernight: true,
          timeText: '',
          availableHeight: availableHeight,
        );
      }
    }

    // Normal work time or start of overnight shift
    final workTime = CalendarService.getDetailedWorkTime(day, controller);
    if (workTime == null) return Container();

    final startHour = workTime['startHour']!;
    final startMinute = workTime['startMinute']!;
    final endHour = workTime['endHour']!;
    final endMinute = workTime['endMinute']!;

    double startPercent = (startHour + startMinute / 60.0) / 24.0;
    double endPercent = (endHour + endMinute / 60.0) / 24.0;

    if (isOvernight && endPercent < startPercent) {
      return _buildSingleWorkBar(
        startPercent: startPercent,
        endPercent: 1.0,
        isOvernight: true,
        timeText: '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
        availableHeight: availableHeight,
      );
    } else {
      return _buildSingleWorkBar(
        startPercent: startPercent,
        endPercent: endPercent,
        isOvernight: false,
        timeText: '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
        availableHeight: availableHeight,
      );
    }
  }

  static Widget _buildSingleWorkBar({
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
            if (timeText.isNotEmpty)
              Center(
                child: RotatedBox(
                  quarterTurns: 3,
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

  // DAY VIEW
  static Widget buildDayView(DateTime day, WorkTimeController controller, Function setState) {
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
              ? _buildEmptyDayView(day, controller, setState)
              : _buildDayEntriesList(dayEntries, day, controller, setState),
        ),
      ],
    );
  }

  static Widget _buildEmptyDayView(DateTime day, WorkTimeController controller, Function setState) {
    return Builder(
      builder: (context) => Center(
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
              onPressed: () => CalendarDialogs.showAddEntryDialog(context, day, controller, setState),
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
      ),
    );
  }

  static Widget _buildDayEntriesList(List<Map<String, String>> dayEntries, DateTime day, WorkTimeController controller, Function setState) {
    return Builder(
      builder: (context) => ListView.builder(
        itemCount: dayEntries.length,
        itemBuilder: (context, index) {
          final entry = dayEntries[index];
          final isVacation = entry['type'] == 'vacation';
          final isOvernight = !isVacation && CalendarService.isOvernightWork(day, controller);

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
                                'Nachtarbeit',
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
                  onPressed: () => CalendarDialogs.showDeleteConfirmation(context, day, [entry], controller, setState),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // LEGEND
  static Widget buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.orange.withOpacity(0.7), 'Arbeitstag'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.purple.withOpacity(0.7), 'Nachtarbeit', hasIcon: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green.withOpacity(0.7), 'Urlaub'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blue.withOpacity(0.3), 'Heute', hasBorder: true),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildLegendItem(Color color, String label, {bool hasIcon = false, bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: hasIcon ? const Center(
            child: Icon(
              Icons.nightlight_round,
              color: Colors.yellow,
              size: 10,
            ),
          ) : null,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}