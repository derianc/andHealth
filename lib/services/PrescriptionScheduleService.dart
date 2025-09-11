import 'dart:convert';
import 'package:andhealth/models/medication_event.dart';
import 'package:andhealth/models/prescription_model.dart';
import 'package:dart_openai/dart_openai.dart';

class PrescriptionScheduleService {

  Future<Map<DateTime, List<MedicationEvent>>> getCalendarEvents(
    List<Prescription> prescriptions,
    String startOfDay
  ) async {
    final Map<DateTime, List<MedicationEvent>> events = {};
    final today = DateTime.now();

    for (var p in prescriptions.where((p) => p.isActive)) {
      final frequency = p.frequency;
      final name = p.name;

      final parsed = await _parseFrequencyWithOpenAI(frequency, startOfDay);
      final times = parsed["suggestedTimes"]?.cast<String>() ?? [];

      for (var t in times) {
        final parts = t.split(":");
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        final eventTime = DateTime(
          today.year,
          today.month,
          today.day,
          hour,
          minute,
        );

        final key = DateTime(today.year, today.month, today.day);

        // collapse meds with same time
        final dayEvents = events.putIfAbsent(key, () => []);

        final existing = dayEvents.firstWhere(
          (e) =>
              e.time.hour == eventTime.hour &&
              e.time.minute == eventTime.minute,
          orElse: () => MedicationEvent([], eventTime),
        );

        if (!dayEvents.contains(existing)) {
          dayEvents.add(existing);
        }
        existing.names.add(name);
      }
    }

    // sort by time
    events.forEach((key, dayEvents) {
      dayEvents.sort((a, b) => a.time.compareTo(b.time));
    });

    return events;
  }


  Future<Map<String, dynamic>> _parseFrequencyWithOpenAI(
    String frequency,
    String startOfDay
  ) async {
    print("🤖 Sending to OpenAI: $frequency");

    final response = await OpenAI.instance.chat.create(
      model: "gpt-4o-mini",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "Translate prescription frequencies into structured JSON schedules.",
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "Frequency: $frequency. Return JSON with fields: timesPerDay, intervalHours, suggestedTimes (24h HH:mm format). "
              "Always start the first dose at $startOfDay, and space the remaining doses evenly across the day."
            ),
          ],
        ),
      ],
    );

    // print("🤖 Raw OpenAI response: ${response.choices.first.message.content}");

    final raw = response.choices.first.message.content?.first.text;

    if (raw == null) {
      throw Exception("OpenAI returned no content for frequency=$frequency");
    }

    // Remove markdown fences like ```json ... ```
    final cleaned = raw
        .replaceAll(RegExp(r"^```json", multiLine: true), "")
        .replaceAll(RegExp(r"```$", multiLine: true), "")
        .trim();

    // print("🤖 Cleaned OpenAI text: $cleaned");

    return jsonDecode(cleaned);
  }
}
