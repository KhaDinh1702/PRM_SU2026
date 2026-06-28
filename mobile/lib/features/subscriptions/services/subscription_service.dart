import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../models/subscription_status.dart';

class SubscriptionService {
  const SubscriptionService();

  Future<SubscriptionStatus> getMySubscription() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/subscriptions/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not load subscription');
    }

    return SubscriptionStatus.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<PayOSCheckout> createPayOSCheckout(String plan) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/payments/payos/create-link'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'plan': plan}),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body);
    if (response.statusCode != 201) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not create payment link');
    }

    return PayOSCheckout.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<PaymentStatus> getPaymentStatus(int orderCode) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/payments/$orderCode/status'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Could not check payment status');
    }

    return PaymentStatus.fromJson(Map<String, dynamic>.from(body as Map));
  }
}
