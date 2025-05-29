// lib/screens/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:work_time_app/widgets/main_drawer.dart';
import '../utils/WorkTimeController.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_views.dart';
import '../widgets/calendar_dialogs.dart';

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

  Widget _buildCurrentView(WorkTimeController controller) {
    switch (_currentView) {
      case CalendarView.month:
        return CalendarViews.buildCalendarGrid(_currentMonth, controller, () => setState(() {}));
      case CalendarView.week:
        return CalendarViews.buildWeekView(_currentWeek, controller, () => setState(() {}));
      case CalendarView.day:
        return CalendarViews.buildDayView(_currentDay, controller, () => setState(() {}));
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
                      CalendarService.getViewTitle(_currentView, _currentMonth, _currentWeek, _currentDay),
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
                CalendarViews.buildLegend(),
            ],
          );
        },
      ),
    );
  }
}