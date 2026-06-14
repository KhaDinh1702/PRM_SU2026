import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../models/calendar_item.dart';
import '../utils/calendar_utils.dart';

class CalendarService {
  const CalendarService();

  Future<List<CalendarItem>> fetchCalendarItems({
    required DateTime start,
    required DateTime end,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${AuthService.apiBaseUrl}/calendar/events')
        .replace(queryParameters: {
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final rawItems = jsonDecode(response.body) as List<dynamic>;
    final mappedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(mapCalendarPayload)
        .whereType<CalendarItem>()
        .toList();

    return sortCalendarItemsByTime(mappedItems);
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required String type,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/calendar/events'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'description': description,
            'startTime': startTime.toUtc().toIso8601String(),
            'endTime': startTime
                .add(const Duration(hours: 1))
                .toUtc()
                .toIso8601String(),
            'type': type,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  Future<void> createPersonalTask({
    required String title,
    required String description,
    required String priority,
    required DateTime dueDateTime,
    required String reminderType,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/tasks'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'description': description,
            'status': 'Pending',
            'priority': priority,
            'dueDate': dueDateTime.toUtc().toIso8601String(),
            'deadline': dueDateTime.toUtc().toIso8601String(),
            'dueTime':
                '${dueDateTime.hour.toString().padLeft(2, '0')}:${dueDateTime.minute.toString().padLeft(2, '0')}',
            'reminderType': reminderType,
            'notificationEnabled': reminderType != 'none',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${AuthService.apiBaseUrl}/calendar/events/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
}
