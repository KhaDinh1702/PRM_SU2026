class SubscriptionStatus {
  final String plan;
  final String status;
  final bool isPro;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? provider;

  const SubscriptionStatus({
    required this.plan,
    required this.status,
    required this.isPro,
    this.startDate,
    this.endDate,
    this.provider,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'free',
      isPro: json['isPro'] == true,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      provider: json['provider']?.toString(),
    );
  }

  static const free = SubscriptionStatus(
    plan: 'free',
    status: 'free',
    isPro: false,
  );
}

class PayOSCheckout {
  final int orderCode;
  final String checkoutUrl;
  final String qrCode;
  final int amount;
  final String status;
  final String plan;

  const PayOSCheckout({
    required this.orderCode,
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.status,
    required this.plan,
  });

  factory PayOSCheckout.fromJson(Map<String, dynamic> json) {
    return PayOSCheckout(
      orderCode: int.tryParse(json['orderCode']?.toString() ?? '') ?? 0,
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      amount: int.tryParse(json['amount']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      plan: json['plan']?.toString() ?? '',
    );
  }
}

class PaymentStatus {
  final int orderCode;
  final String status;
  final String providerStatus;
  final int amount;
  final String plan;
  final DateTime? paidAt;
  final SubscriptionStatus subscription;

  const PaymentStatus({
    required this.orderCode,
    required this.status,
    required this.providerStatus,
    required this.amount,
    required this.plan,
    required this.subscription,
    this.paidAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final subscriptionJson = json['subscription'];
    return PaymentStatus(
      orderCode: int.tryParse(json['orderCode']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      providerStatus: json['providerStatus']?.toString() ?? '',
      amount: int.tryParse(json['amount']?.toString() ?? '') ?? 0,
      plan: json['plan']?.toString() ?? '',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
      subscription: subscriptionJson is Map
          ? SubscriptionStatus.fromJson(
              Map<String, dynamic>.from(subscriptionJson),
            )
          : SubscriptionStatus.free,
    );
  }
}
