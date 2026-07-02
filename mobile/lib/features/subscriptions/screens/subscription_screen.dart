import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';
import 'payos_checkout_screen.dart';

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

  List<_PlanDetails> get _plans => [
        _PlanDetails(
          id: 'pro_monthly',
          title: 'Pro Monthly',
          price: _currency.format(29000),
          duration: LocaleService.tr('30 ngay', en: '30 days'),
          subtitle: LocaleService.tr(
            'Mo khoa tinh nang Pro trong 30 ngay',
            en: 'Unlock Pro features for 30 days',
          ),
          icon: Icons.calendar_month_rounded,
          accent: const Color(0xFF06B6D4),
          benefits: [
            LocaleService.tr(
              'Khong gioi han task ca nhan va project',
              en: 'Unlimited personal tasks and projects',
            ),
            LocaleService.tr(
              'Gan dia diem vao task va mo chi duong trong app',
              en: 'Attach locations to tasks and open in-app directions',
            ),
            LocaleService.tr(
              'Tim va chon dia diem truc tiep tren ban do',
              en: 'Search and pick places directly on the map',
            ),
            LocaleService.tr(
              'Tinh tuyen duong trong app cho task co dia diem',
              en: 'Compute in-app routes for tasks with locations',
            ),
            LocaleService.tr(
              'Tai khoan tu dong len Pro sau khi PayOS xac nhan thanh toan',
              en: 'Account upgrades automatically after PayOS confirms payment',
            ),
          ],
        ),
        _PlanDetails(
          id: 'pro_yearly',
          title: 'Pro Yearly',
          price: _currency.format(199000),
          duration: LocaleService.tr('365 ngay', en: '365 days'),
          subtitle: LocaleService.tr(
            'Tiet kiem hon cho mot nam su dung',
            en: 'Better value for one year of Pro',
          ),
          icon: Icons.workspace_premium_rounded,
          accent: const Color(0xFFF59E0B),
          highlight: LocaleService.tr(
            'Tiet kiem hon so voi tra theo thang',
            en: 'Better value than paying monthly',
          ),
          benefits: [
            LocaleService.tr(
              'Toan bo quyen loi cua Pro Monthly',
              en: 'Everything included in Pro Monthly',
            ),
            LocaleService.tr(
              'Dung Pro lien tuc trong mot nam',
              en: 'A full year of Pro access',
            ),
            LocaleService.tr(
              'Phu hop de demo va bao ve do an voi day du tinh nang',
              en: 'Best for demonstrating the full feature set',
            ),
            LocaleService.tr(
              'Gia tot hon neu su dung lau dai',
              en: 'Lower cost for long-term use',
            ),
          ],
        ),
      ];

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
      if (!mounted) return;
      setState(() {
        _pendingOrderCode = checkout.orderCode;
        _busy = false;
      });
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PayOSCheckoutScreen(
            checkoutUrl: checkout.checkoutUrl,
            orderCode: checkout.orderCode,
          ),
        ),
      );
      if (completed == true && mounted) {
        await _checkPendingPayment();
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

  Future<void> _openPlanDetails(_PlanDetails plan) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanDetailsSheet(
        plan: plan,
        busy: _busy,
        onPay: () {
          Navigator.of(context).pop();
          _buy(plan.id);
        },
      ),
    );
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
                      _FreePlanLimitsCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        captionColor: captionColor,
                      ),
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
                      for (final plan in _plans) ...[
                        _PlanCard(
                          plan: plan,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          busy: _busy,
                          onTap: () => _openPlanDetails(plan),
                        ),
                        const SizedBox(height: 12),
                      ],
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
  final _PlanDetails plan;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final bool busy;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
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
                  color: plan.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(plan.icon, color: plan.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.subtitle,
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
                    plan.price,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.info_outline_rounded, color: subTextColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreePlanLimitsCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;

  const _FreePlanLimitsCard({
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final verifiedItems = [
      LocaleService.tr(
        'Toi da 20 task ca nhan tren goi Free.',
        en: 'Up to 20 personal tasks on Free.',
      ),
      LocaleService.tr(
        'Toi da 3 project tren goi Free.',
        en: 'Up to 3 projects on Free.',
      ),
      LocaleService.tr(
        'Task gan dia diem, tim dia diem tren ban do va chi duong trong app can Pro.',
        en: 'Location tasks, map search, and in-app directions require Pro.',
      ),
      LocaleService.tr(
        'Task thuong, focus timer va lich van dung duoc tren Free.',
        en: 'Basic tasks, focus timer, and calendar still work on Free.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr(
                        'Gioi han goi Free',
                        en: 'Free plan limits',
                      ),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr(
                        'Da duoc enforce boi backend',
                        en: 'Enforced by the backend',
                      ),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in verifiedItems) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.95),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PlanDetails {
  final String id;
  final String title;
  final String price;
  final String duration;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> benefits;
  final String? highlight;

  const _PlanDetails({
    required this.id,
    required this.title,
    required this.price,
    required this.duration,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.benefits,
    this.highlight,
  });
}

class _PlanDetailsSheet extends StatelessWidget {
  final _PlanDetails plan;
  final bool busy;
  final VoidCallback onPay;

  const _PlanDetailsSheet({
    required this.plan,
    required this.busy,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subTextColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: plan.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(plan.icon, color: plan.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  plan.duration,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            plan.price,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        plan.subtitle,
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      if (plan.highlight != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: plan.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: plan.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sell_rounded,
                                color: plan.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plan.highlight!,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        LocaleService.tr('Quyen loi', en: 'Benefits'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final benefit in plan.benefits) ...[
                        _BenefitRow(
                          text: benefit,
                          accent: plan.accent,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : onPay,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payments_rounded),
                      label: Text(
                        LocaleService.tr(
                          'Thanh toan bang PayOS',
                          en: 'Pay with PayOS',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: plan.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
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

class _BenefitRow extends StatelessWidget {
  final String text;
  final Color accent;
  final Color textColor;

  const _BenefitRow({
    required this.text,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check_rounded, color: accent, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
