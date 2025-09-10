import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:andhealth/models/medication_event.dart';
import 'package:andhealth/providers/prescription_provider.dart';
import '../providers/user_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    // load prescriptions from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<UserProvider>().user;
      if (user == null) return;

      final pp = context.read<PrescriptionProvider>();

      if (!pp.isLoaded) {
        await pp.loadPrescriptions(user.id);
      }

      await pp.ensureEventsBuilt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: !pp.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : pp.prescriptions.isEmpty
              ? const Center(child: Text("No prescriptions found"))
              : pp.isBuildingEvents
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCalendar(pp.events),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<MedicationEvent>> events) {
    return Column(
      children: [
        TableCalendar<MedicationEvent>(
          firstDay: DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day),
          lastDay: DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return events[key] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, reminders) {
              if (reminders.isNotEmpty) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      reminders.length.clamp(0, 3),
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const Divider(),
       Expanded(
          child: ListView(
            children:
                (events[DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                        )] ??
                        [])
                    .map(
                      (e) => ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.blue,
                        ),
                        title: Text(
                          "${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}",
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Take Medications:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...e.names.map((name) => Text(" • $name")),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        )
      ],
    );
  }
}
