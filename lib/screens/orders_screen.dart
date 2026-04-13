import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../services/firestore_service.dart';
import '../services/firebase_service.dart';
import 'order_detail_screen.dart';
import '../utils/require_auth.dart';
import '../widgets/cart_icon_button.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _userId;
  bool _userIdReady = false;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    String? userId;
    if (FirebaseService.auth?.currentUser != null) {
      userId = FirebaseService.auth!.currentUser!.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user');
    }
    setState(() {
      _userId = userId;
      _userIdReady = true;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Shipped':
        return AppColors.primary;
      case 'Confirmed':
        return AppColors.warning;
      case 'Paid':
        return AppColors.success;
      case 'Cancelled':
        return Colors.red;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_userIdReady) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userId == null || _userId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textLight),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sign in to see your orders',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    if (!await ensureSignedIn(context) || !context.mounted) return;
                    await _getUserId();
                  },
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.getUserOrders(_userId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('No orders yet', style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _getUserId();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = order['status'] ?? 'Pending';
                final total = (order['total'] as num?)?.toDouble() ?? 0.0;
                final items = order['items'] as List? ?? [];
                final createdAt = order['createdAt'];
                final dateStr = createdAt != null
                    ? DateFormat('MMM dd, yyyy HH:mm').format(
                        (createdAt as dynamic).toDate(),
                      )
                    : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    title: Text('Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr),
                        const SizedBox(height: AppSpacing.xs),
                        ...items.take(2).map((item) => Text(
                              '${item['productName'] ?? 'Unknown'} x${item['quantity'] ?? 1}',
                              style: AppTextStyles.bodySmall,
                            )),
                        if (items.length > 2)
                          Text(
                            '+${items.length - 2} more items',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '₹${total.toInt()}',
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                    onTap: () {
                      // Convert Firestore order to Order model for detail screen
                      final orderModel = _convertToOrderModel(order);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: orderModel),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Convert Firestore order data to Order model
  Order _convertToOrderModel(Map<String, dynamic> orderData) {
    final items = (orderData['items'] as List? ?? []).map((item) {
      return OrderItem(
        productName: item['productName'] ?? 'Unknown',
        quantity: item['quantity'] ?? 1,
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final createdAt = orderData['createdAt'];
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format((createdAt as dynamic).toDate())
        : 'Unknown date';

    final deliveryAddress = orderData['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final address = deliveryAddress['address'] ?? 'Address not available';

    final note = orderData['trackingNote'] ?? orderData['deliveryNote'];
    final trackingNote = note != null ? note.toString().trim() : null;

    return Order(
      id: orderData['id'] ?? '',
      date: dateStr,
      status: orderData['status'] ?? 'Pending',
      total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
      items: items,
      address: address.toString(),
      trackingNote: (trackingNote != null && trackingNote.isNotEmpty) ? trackingNote : null,
    );
  }
}

// Order model (matching the one in api_service.dart)
class Order {
  final String id;
  final String date;
  final String status;
  final double total;
  final List<OrderItem> items;
  final String address;
  /// Optional note from admin (e.g. rider phone, delay) — Firestore `trackingNote` or `deliveryNote`.
  final String? trackingNote;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    required this.address,
    this.trackingNote,
  });
}

class OrderItem {
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });
}
