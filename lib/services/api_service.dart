import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String date;
  final String address;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.date,
    required this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    total: (json['total'] as num).toDouble(),
    status: json['status'],
    date: json['date'],
    address: json['address'],
  );
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
  );
}

class Subscription {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String type;
  final String status;
  final String nextDelivery;

  Subscription({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.type,
    required this.status,
    required this.nextDelivery,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'],
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    type: json['type'],
    status: json['status'],
    nextDelivery: json['nextDelivery'],
  );
}

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $userId',
    };
  }

  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String address,
    required String paymentId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
        body: json.encode({
          'items': items,
          'address': address,
          'paymentId': paymentId,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      print('Create Order Error: $e');
      rethrow;
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Orders Error: $e');
      return [];
    }
  }

  Future<Subscription> createSubscription({
    required String productId,
    required int quantity,
    required String type,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions'),
        headers: await _getHeaders(),
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
          'type': type,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        return Subscription.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create subscription');
      }
    } catch (e) {
      print('Create Subscription Error: $e');
      rethrow;
    }
  }

  Future<List<Subscription>> getSubscriptions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subscription.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Subscriptions Error: $e');
      return [];
    }
  }

  Future<Subscription> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: await _getHeaders(),
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        return Subscription.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update subscription');
      }
    } catch (e) {
      print('Update Subscription Error: $e');
      rethrow;
    }
  }
}

