import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Girgo payments (Razorpay).
///
/// **One-time checkout** — [initiatePayment] (current cart / first delivery charge).
///
/// **True auto-pay each billing cycle** needs [Razorpay Subscriptions](https://razorpay.com/docs/payments/subscriptions/)
/// on your server: create Plan → create Subscription → pass `subscription_id` to the app and call
/// [openRecurringSubscriptionCheckout]. The Flutter SDK opens the same native sheet to authorize the mandate.
///
/// **iOS:** Razorpay’s SDK works on iPhone for real-world goods (e.g. milk delivery). Apple may require
/// In-App Purchase for *digital* subscriptions; physical delivery subscriptions are usually fine with
/// external payment—confirm with your legal/App Review notes. Use Razorpay’s latest iOS integration checklist.
class PaymentService {
  static const String _razorpayKeyId = 'rzp_live_RnTsEY6gc24CbY';
  late final Razorpay _razorpay;
  Completer<String>? _activePaymentCompleter;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Opens Razorpay **Subscription** checkout (recurring mandate). [subscriptionId] must be `sub_...`
  /// from your backend (Razorpay Subscriptions API). Returns Razorpay payment id on success.
  Future<String> openRecurringSubscriptionCheckout({
    required String subscriptionId,
    String description = 'Girgo subscription',
    String? contact,
    String? email,
    String? name,
  }) async {
    if (_activePaymentCompleter != null) {
      _activePaymentCompleter!
          .completeError(Exception('Another payment is already in progress.'));
      _activePaymentCompleter = null;
    }

    final completer = Completer<String>();
    _activePaymentCompleter = completer;

    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'subscription_id': subscriptionId,
      'name': (name != null && name.isNotEmpty) ? name : 'Girgo',
      'description': description,
      'prefill': {
        'contact': (contact != null && contact.isNotEmpty) ? contact : '9999999999',
        'email': (email != null && email.isNotEmpty) ? email : 'customer@example.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _activePaymentCompleter = null;
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<String> initiatePayment({
    required double amount,
    String description = 'Girgo Order Payment',
    String? contact,
    String? email,
    String? name,
  }) async {
    if (_activePaymentCompleter != null) {
      _activePaymentCompleter!
          .completeError(Exception('Another payment is already in progress.'));
      _activePaymentCompleter = null;
    }

    final completer = Completer<String>();
    _activePaymentCompleter = completer;

    final options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': (name != null && name.isNotEmpty) ? name : 'Girgo',
      'description': description,
      'prefill': {
        'contact': (contact != null && contact.isNotEmpty) ? contact : '9999999999',
        'email': (email != null && email.isNotEmpty) ? email : 'customer@example.com',
      },
      'external': {
        'wallets': ['paytm']
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _activePaymentCompleter = null;
      completer.completeError(e);
    }

    return completer.future;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _activePaymentCompleter?.complete(response.paymentId ?? '');
    _activePaymentCompleter = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _activePaymentCompleter?.completeError(
      Exception(response.message ?? 'Payment failed'),
    );
    _activePaymentCompleter = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _activePaymentCompleter?.completeError(
      Exception('Please complete the payment inside Razorpay'),
    );
    _activePaymentCompleter = null;
  }

  void dispose() {
    _activePaymentCompleter = null;
    _razorpay.clear();
  }
}

