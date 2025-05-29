import 'package:flutter/material.dart';
import 'package:work_time_app/utils/WorkTimeController.dart';
import 'package:work_time_app/widgets/main_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showHourlyWageDialog(WorkTimeController controller) {
    final TextEditingController wageController = TextEditingController(
      text: controller.hourlyWage,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Stundenlohn bearbeiten',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geben Sie Ihren Stundenlohn in Euro ein:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wageController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '€ pro Stunde',
                  hintText: 'z.B. 15,50',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
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
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newWage = wageController.text.trim();
                      if (newWage.isNotEmpty) {
                        final parsedWage = double.tryParse(newWage.replaceAll(',', '.'));
                        if (parsedWage != null && parsedWage > 0) {
                          controller.hourlyWage = newWage;
                          await controller.saveSettings();
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stundenlohn auf ${newWage}€ geändert'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bitte geben Sie einen gültigen Betrag ein'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        controller.hourlyWage = '';
                        await controller.saveSettings();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stundenlohn zurückgesetzt'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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

  void _showNightWageDialog(WorkTimeController controller) {
    final TextEditingController nightWageController = TextEditingController(
      text: controller.nightHourlyWage,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Nacht-Stundenlohn bearbeiten',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geben Sie Ihren Nacht-Stundenlohn in Euro ein:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nightWageController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '€ pro Stunde (Nacht)',
                  hintText: 'z.B. 20,00',
                  prefixIcon: Icon(Icons.nightlight_round),
                  border: OutlineInputBorder(),
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
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newWage = nightWageController.text.trim();
                      if (newWage.isNotEmpty) {
                        final parsedWage = double.tryParse(newWage.replaceAll(',', '.'));
                        if (parsedWage != null && parsedWage > 0) {
                          controller.nightHourlyWage = newWage;
                          await controller.saveSettings();
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nacht-Stundenlohn auf ${newWage}€ geändert'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bitte geben Sie einen gültigen Betrag ein'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        controller.nightHourlyWage = '';
                        await controller.saveSettings();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nacht-Stundenlohn zurückgesetzt'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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

  void _showTimeDialog(WorkTimeController controller, bool isFromTime) {
    final currentTime = isFromTime
        ? controller.nightBonusFrom
        : controller.nightBonusTo;

    final int initialHour = currentTime.isNotEmpty
        ? int.tryParse(currentTime) ?? (isFromTime ? 22 : 6)
        : (isFromTime ? 22 : 6);

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    ).then((TimeOfDay? time) {
      if (time != null) {
        if (isFromTime) {
          controller.nightBonusFrom = time.hour.toString();
        } else {
          controller.nightBonusTo = time.hour.toString();
        }
        controller.saveSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isFromTime ? "Von" : "Bis"}-Zeit auf ${time.hour}:00 geändert'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showDeleteConfirmDialog(WorkTimeController controller, bool isWorkDays) {
    final String title = isWorkDays ? 'Arbeitstage löschen' : 'Urlaubstage löschen';
    final String content = isWorkDays
        ? 'Möchten Sie wirklich alle Arbeitstage unwiderruflich löschen?'
        : 'Möchten Sie wirklich alle Urlaubstage unwiderruflich löschen?';
    final Color buttonColor = isWorkDays ? const Color(0xFFFF5722) : const Color(0xFFFF9800);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diese Aktion kann nicht rückgängig gemacht werden!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
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
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      // Hier würde die Löschlogik implementiert werden
                      if (isWorkDays) {
                        await controller.deleteAllWorkDays();
                      } else {
                        await controller.deleteAllVacationDays();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isWorkDays
                              ? 'Alle Arbeitstage wurden gelöscht'
                              : 'Alle Urlaubstage wurden gelöscht'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text(
                      'Löschen',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const MainDrawer(),
      body: Consumer<WorkTimeController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stundenlohn-Container (klickbar)
                GestureDetector(
                  onTap: () => _showHourlyWageDialog(controller),
                  child: Container(
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.euro,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Stundenlohn: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          controller.hourlyWage.isEmpty
                              ? 'Nicht festgelegt'
                              : '${controller.hourlyWage}€/Std',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.hourlyWage.isEmpty
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Nachtzuschlag-Sektion
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: controller.nightBonusEnabled
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.nightBonusEnabled
                          ? Colors.purple.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nachtzuschlag Checkbox
                      CheckboxListTile(
                        title: const Text(
                          'Nachtzuschlag',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        value: controller.nightBonusEnabled,
                        onChanged: (value) async {
                          controller.nightBonusEnabled = value ?? false;
                          await controller.saveSettings();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.nightBonusEnabled
                                  ? 'Nachtzuschlag aktiviert'
                                  : 'Nachtzuschlag deaktiviert'),
                              backgroundColor: controller.nightBonusEnabled
                                  ? Colors.green
                                  : Colors.blue,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 16),

                      // Nacht-Stundenlohn
                      GestureDetector(
                        onTap: controller.nightBonusEnabled
                            ? () => _showNightWageDialog(controller)
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: controller.nightBonusEnabled
                                ? Colors.white
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: controller.nightBonusEnabled
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                color: controller.nightBonusEnabled
                                    ? Colors.purple
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Nacht-Stundenlohn (€): ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: controller.nightBonusEnabled
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                controller.nightHourlyWage.isEmpty
                                    ? 'Nicht festgelegt'
                                    : '${controller.nightHourlyWage}€',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: controller.nightBonusEnabled
                                      ? (controller.nightHourlyWage.isEmpty
                                      ? Colors.orange
                                      : Colors.green)
                                      : Colors.grey,
                                ),
                              ),
                              if (controller.nightBonusEnabled) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.purple,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Von/Bis Zeiten
                      Row(
                        children: [
                          // Von Zeit
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.nightBonusEnabled
                                  ? () => _showTimeDialog(controller, true)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: controller.nightBonusEnabled
                                      ? Colors.white
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: controller.nightBonusEnabled
                                        ? Colors.purple.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Von',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: controller.nightBonusEnabled
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.nightBonusFrom.isEmpty
                                          ? '--:--'
                                          : '${controller.nightBonusFrom}:00',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: controller.nightBonusEnabled
                                            ? Colors.purple
                                            : Colors.grey,
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
                              onTap: controller.nightBonusEnabled
                                  ? () => _showTimeDialog(controller, false)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: controller.nightBonusEnabled
                                      ? Colors.white
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: controller.nightBonusEnabled
                                        ? Colors.purple.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bis',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: controller.nightBonusEnabled
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.nightBonusTo.isEmpty
                                          ? '--:--'
                                          : '${controller.nightBonusTo}:00',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: controller.nightBonusEnabled
                                            ? Colors.purple
                                            : Colors.grey,
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
                  ),
                ),

                const SizedBox(height: 24),

                // Daten löschen Buttons
                Row(
                  children: [
                    // Arbeitstage löschen Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(controller, true),
                        icon: const Icon(Icons.work_off, size: 20),
                        label: const Text(
                          'Arbeitstage\nLöschen',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 60),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Urlaubstage löschen Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(controller, false),
                        icon: const Icon(Icons.beach_access_outlined, size: 20),
                        label: const Text(
                          'Urlaubstage\nLöschen',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 60),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Platzhalter für weitere Einstellungen
                const Text(
                  'Weitere Einstellungen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Hier können später weitere Benutzereinstellungen hinzugefügt werden.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}