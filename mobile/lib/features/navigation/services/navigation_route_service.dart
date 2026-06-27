import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../services/auth_service.dart';
import '../../tasks/models/task_model.dart';
import '../models/route_info.dart';

class NavigationRouteService {
  const NavigationRouteService();

  Future<RouteInfo> computeRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/navigation/route'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'origin': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
            'destination': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
            'travelMode': 'DRIVE',
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not compute route');
    }

    return RouteInfo.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<TaskLocation> geocodeAddress(String address) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/navigation/geocode'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'address': address}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not find this address');
    }

    return TaskLocation.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<TaskLocation> reverseGeocode(LatLng point) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/navigation/reverse-geocode'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'latitude': point.latitude,
            'longitude': point.longitude,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not read this location');
    }

    return TaskLocation.fromJson(Map<String, dynamic>.from(body as Map));
  }
}
