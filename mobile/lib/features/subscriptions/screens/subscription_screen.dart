import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = const SubscriptionService();
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');
  SubscriptionStatus _subscription = SubscriptionStatus.free;
  int? _pendingOrderCode;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subscription = await _service.getMySubscription();
      if (!mounted) return;
      setState(() => _subscription = subscription);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy(String plan) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final checkout = await _service.createPayOSCheckout(plan);
      _pendingOrderCode = checkout.orderCode;
      final uri = Uri.parse(checkout.checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not open PayOS checkout');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkPendingPayment() async {
    final orderCode = _pendingOrderCode;
    if (orderCode == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await _service.getPaymentStatus(orderCode);
      if (!mounted) return;
      setState(() {
        _subscription = status.subscription;
        if (status.status == 'paid') _pendingOrderCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.status == 'paid'
                ? LocaleService.tr('Thanh toan thanh cong',
                    en: 'Payment confirmed')
                : LocaleService.tr('Dang cho thanh toan',
                    en: 'Payment is still pending'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _cleanError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.isDarkMode,
        LocaleService.languageCode,
      ]),
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final cardColor = ThemeService.getCardColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);
        final primary = ThemeService.getPrimaryColor(isDark);

        return Scaffold(
          backgroundColor: ThemeService.getBackgroundColor(isDark),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: textColor,
            title: Text(
              LocaleService.tr('Goi Pro', en: 'Pro plan'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: primary))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _CurrentPlanCard(
                        subscription: _subscription,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        primary: primary,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBox(error: _error!),
                      ],
                      if (_pendingOrderCode != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy ? null : _checkPendingPayment,
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.verified_rounded),
                          label: Text(
                            LocaleService.tr(
                              'Toi da thanh toan',
                              en: 'I have paid',
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        LocaleService.tr('Chon goi', en: 'Choose a plan'),
                        style: TextStyle(
                          color: captionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        title: 'Pro Monthly',
                        price: _currency.format(29000),
                        subtitle: LocaleService.tr(
                          'Mo khoa tinh nang Pro trong 30 ngay',
                          en: 'Unlock Pro features for 30 days',
                        ),
                        icon: Icons.calendar_month_rounded,
                        accent: const Color(0xFF06B6D4),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        busy: _busy,
                        onTap: () => _buy('pro_monthly'),
                      ),
                      const SizedBox(height: 12),
                      _PlanCard(
                        title: 'Pro Yearly',
                        price: _currency.format(199000),
                        subtitle: LocaleService.tr(
                          'Tiet kiem hon cho mot nam su dung',
                          en: 'Better value for one year of Pro',
                        ),
                        icon: Icons.workspace_premium_rounded,
                        accent: const Color(0xFFF59E0B),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        busy: _busy,
                        onTap: () => _buy('pro_yearly'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionStatus subscription;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final Color primary;

  const _CurrentPlanCard({
    required this.subscription,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final subtitle = subscription.isPro && subscription.endDate != null
        ? '${LocaleService.tr('Het han', en: 'Expires')} ${formatter.format(subscription.endDate!)}'
        : LocaleService.tr(
            'Dang dung goi mien phi',
            en: 'You are currently on the free plan',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              subscription.isPro
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_open_rounded,
              color: primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.isPro ? 'FlowMate Pro' : 'FlowMate Free',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final bool busy;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, color: subTextColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;

  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Text(
        error,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
