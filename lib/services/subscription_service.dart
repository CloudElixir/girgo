import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/products.dart';

class Subscription {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final String type; // Daily, Weekly, Monthly
  final String status; // Active, Paused, Cancelled
  final String nextDelivery;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.type,
    this.status = 'Active',
    required this.nextDelivery,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'quantity': quantity,
        'price': price,
        'type': type,
        'status': status,
        'nextDelivery': nextDelivery,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'],
        productId: json['productId'],
        productName: json['productName'],
        productImage: json['productImage'],
        quantity: json['quantity'],
        price: (json['price'] as num).toDouble(),
        type: json['type'],
        status: json['status'] ?? 'Active',
        nextDelivery: json['nextDelivery'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SubscriptionService {
  static const String _subscriptionsKey = 'girgo_subscriptions';

  Future<List<Subscription>> getSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionsJson = prefs.getString(_subscriptionsKey);
      if (subscriptionsJson == null) return [];

      final List<dynamic> subscriptionsData = json.decode(subscriptionsJson);
      return subscriptionsData.map((item) => Subscription.fromJson(item)).toList();
    } catch (e) {
      print('Get Subscriptions Error: $e');
      return [];
    }
  }

  Future<void> addSubscription({
    required Product product,
    required int quantity,
    required String type,
    String status = 'Pending', // Default to 'Pending' - waiting for payment approval
  }) async {
    try {
      final subscriptions = await getSubscriptions();
      
      // Calculate next delivery date based on type
      final nextDelivery = _calculateNextDelivery(type);
      
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        productName: product.name,
        productImage: product.image,
        quantity: quantity,
        price: product.subscriptionPrice ?? product.price,
        type: type,
        status: status,
        nextDelivery: nextDelivery,
        createdAt: DateTime.now(),
      );

      subscriptions.add(subscription);
      await _saveSubscriptions(subscriptions);
    } catch (e) {
      print('Add Subscription Error: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    try {
      final subscriptions = await getSubscriptions();
      final index = subscriptions.indexWhere((s) => s.id == subscriptionId);
      
      if (index >= 0) {
        final subscription = subscriptions[index];
        final updatedSubscription = Subscription(
          id: subscription.id,
          productId: subscription.productId,
          productName: subscription.productName,
          productImage: subscription.productImage,
          quantity: updates['quantity'] ?? subscription.quantity,
          price: subscription.price,
          type: subscription.type,
          status: updates['status'] ?? subscription.status,
          nextDelivery: updates['nextDelivery'] ?? subscription.nextDelivery,
          createdAt: subscription.createdAt,
        );
        subscriptions[index] = updatedSubscription;
        await _saveSubscriptions(subscriptions);
      }
    } catch (e) {
      print('Update Subscription Error: $e');
      rethrow;
    }
  }

  Future<void> removeSubscription(String subscriptionId) async {
    try {
      final subscriptions = await getSubscriptions();
      subscriptions.removeWhere((s) => s.id == subscriptionId);
      await _saveSubscriptions(subscriptions);
    } catch (e) {
      print('Remove Subscription Error: $e');
      rethrow;
    }
  }

  String _calculateNextDelivery(String type) {
    final now = DateTime.now();
    switch (type) {
      case 'Daily':
        return _formatDate(now.add(const Duration(days: 1)));
      case 'Weekly':
        return _formatDate(now.add(const Duration(days: 7)));
      case 'Monthly':
        return _formatDate(DateTime(now.year, now.month + 1, now.day));
      default:
        return _formatDate(now.add(const Duration(days: 1)));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionsJson = json.encode(
      subscriptions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_subscriptionsKey, subscriptionsJson);
  }
}

