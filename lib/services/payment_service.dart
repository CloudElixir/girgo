import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

