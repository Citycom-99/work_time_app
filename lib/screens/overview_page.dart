import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../utils/WorkTimeController.dart';
import '../widgets/main_drawer.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final WorkTimeController _controller = WorkTimeController();
  final List<String> _months = [];
  final Map<String, String> _monthToKey = {};
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('de_DE', null).then((_) {
      final now = DateTime.now();
      final months = List.generate(12, (i) {
        final date = DateTime(now.year, i + 1);
        final key = DateFormat('yyyy-MM').format(date);
        final label = DateFormat.MMMM('de_DE').format(date);
        _monthToKey[label] = key;
        return label;
      });

      setState(() {
        _months.insert(0, 'Alle'); // Füge "Alle" an die erste Position ein
        _months.addAll(months);

        // Aktueller Monat als Standard statt "Alle"
        final currentMonthKey = DateFormat('yyyy-MM').format(now); // Schlüssel verwenden, nicht Label
        final initialMonthLabel = currentMonthKey; // Standardmäßig aktuellen Monat auswählen

        Provider.of<WorkTimeController>(context, listen: false)
            .updateSelectedMonth(initialMonthLabel);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WorkTimeController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Übersicht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              final controller = Provider.of<WorkTimeController>(context, listen: false);
              controller.openSettingsDialog(context);
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedMonth,
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      onChanged: (newLabel) {
                        if (newLabel != null) {
                          controller.updateSelectedMonth(newLabel);
                        }
                      },
                      items: _months
                          .map((month) => DropdownMenuItem(
                        value: month == 'Alle' ? 'Alle' : _monthToKey[month],
                        child: Text(month),
                      ))
                          .toList(),
                    ),
                  ),
                ),
                Container(
                  child: GestureDetector(
                    onTap: () {
                      controller.toggleVacationDisplay();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: controller.showVacationDays,
                          onChanged: (value) {
                            controller.toggleVacationDisplay();
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'Urlaub anzeigen',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: controller.buildDataTable(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Gesamt: ${controller.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
          controller.addWorkEntry(context);
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
          child: FloatingActionButton(
            onPressed: null, // onPressed auf null setzen, da GestureDetector das übernimmt
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}