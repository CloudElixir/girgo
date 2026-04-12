import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../constants/products.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions => 
      _subscriptions.where((s) => s.status == 'Active').toList();

  SubscriptionProvider() {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    _subscriptions = await _subscriptionService.getSubscriptions();
    notifyListeners();
  }

  Future<void> addSubscription({
    required Product product,
    required int quantity,
    required String type,
    String status = 'Pending', // Default to 'Pending' - waiting for payment approval
  }) async {
    await _subscriptionService.addSubscription(
      product: product,
      quantity: quantity,
      type: type,
      status: status,
    );
    await loadSubscriptions();
  }

  Future<void> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    await _subscriptionService.updateSubscription(subscriptionId, updates);
    await loadSubscriptions();
  }

  Future<void> removeSubscription(String subscriptionId) async {
    await _subscriptionService.removeSubscription(subscriptionId);
    await loadSubscriptions();
  }
}

