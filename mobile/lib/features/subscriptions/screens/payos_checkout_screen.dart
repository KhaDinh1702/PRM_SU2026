import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';

class PayOSCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final int orderCode;

  const PayOSCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.orderCode,
  });

  @override
  State<PayOSCheckoutScreen> createState() => _PayOSCheckoutScreenState();
}

class _PayOSCheckoutScreenState extends State<PayOSCheckoutScreen> {
  final _service = const SubscriptionService();
  late final WebViewController _controller;
  Timer? _statusTimer;
  int _progress = 0;
  bool _checkingStatus = false;
  bool _confirmingPayment = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _error = error.description;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final path = uri?.path.toLowerCase() ?? '';
            if (path.contains('/payment/success')) {
              if (mounted) {
                setState(() => _confirmingPayment = true);
              }
              unawaited(_checkPaymentStatus());
              return NavigationDecision.prevent;
            }
            if (path.contains('/payment/cancel')) {
              if (mounted) {
                setState(() => _confirmingPayment = true);
              }
              unawaited(_checkPaymentStatus());
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_checkPaymentStatus()),
    );
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkingStatus || !mounted) return;
    _checkingStatus = true;
    try {
      final status = await _service.getPaymentStatus(widget.orderCode);
      if (!mounted) return;

      if (status.status == 'paid') {
        _statusTimer?.cancel();
        Navigator.of(context).pop<PaymentStatus>(status);
        return;
      }

      if ({'cancelled', 'expired', 'failed'}.contains(status.status)) {
        _statusTimer?.cancel();
        Navigator.of(context).pop<PaymentStatus>(status);
      }
    } catch (_) {
      // A temporary status-check failure should not interrupt PayOS checkout.
    } finally {
      _checkingStatus = false;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Widget _buildWebView() {
    final platformParams = PlatformWebViewWidgetCreationParams(
      controller: _controller.platform,
    );
    if (_controller.platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams
            .fromPlatformWebViewWidgetCreationParams(
          platformParams,
          displayWithHybridComposition: true,
        ),
      );
    }

    return WebViewWidget.fromPlatformCreationParams(params: platformParams);
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
        final primary = ThemeService.getPrimaryColor(isDark);

        return Scaffold(
          backgroundColor: ThemeService.getBackgroundColor(isDark),
          appBar: AppBar(
            backgroundColor: ThemeService.getBackgroundColor(isDark),
            foregroundColor: textColor,
            elevation: 0,
            title: Text(
              LocaleService.tr('Thanh toan PayOS', en: 'PayOS checkout'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: LocaleService.tr('Tai lai', en: 'Reload'),
                onPressed: () => _controller.reload(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_progress < 100)
                LinearProgressIndicator(
                  value: _progress / 100,
                  color: primary,
                  minHeight: 2,
                ),
              Expanded(
                child: Stack(
                  children: [
                    ColoredBox(
                      color: Colors.white,
                      child: _buildWebView(),
                    ),
                    if (_progress < 100 && _error == null)
                      Center(
                        child: CircularProgressIndicator(color: primary),
                      ),
                    if (_error != null)
                      _CheckoutError(
                        error: _error!,
                        onRetry: () {
                          setState(() => _error = null);
                          _controller.reload();
                        },
                      ),
                    if (_confirmingPayment && _error == null)
                      _ConfirmingPayment(primary: primary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfirmingPayment extends StatelessWidget {
  final Color primary;

  const _ConfirmingPayment({required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return ColoredBox(
      color: ThemeService.getBackgroundColor(isDark),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primary),
              const SizedBox(height: 18),
              Text(
                LocaleService.tr(
                  'Dang xac nhan thanh toan',
                  en: 'Confirming payment',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                LocaleService.tr(
                  'Tai khoan se tu dong nang cap sau khi PayOS xac nhan.',
                  en: 'Your account will upgrade automatically once PayOS confirms.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _CheckoutError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return Container(
      color: ThemeService.getBackgroundColor(isDark),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            LocaleService.tr(
              'Khong mo duoc trang thanh toan',
              en: 'Could not load checkout',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(LocaleService.tr('Thu lai', en: 'Retry')),
          ),
        ],
      ),
    );
  }
}
