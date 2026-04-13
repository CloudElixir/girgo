import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'orders_screen.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/order_tracking_timeline.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Shipped':
      case 'Out for Delivery':
        return AppColors.primary;
      case 'Confirmed':
      case 'Packed':
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Information', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Order ID', '#${order.id}'),
            _buildInfoRow('Date', order.date),
            _buildInfoRow('Status', order.status, statusColor: _getStatusColor(order.status)),
            const SizedBox(height: AppSpacing.lg),
            OrderTrackingTimeline(status: order.status),
            if (order.trackingNote != null && order.trackingNote!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery update', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(order.trackingNote!, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Delivery Address', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    order.address,
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Order Items', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: AppTextStyles.body),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toInt()}',
                        style: AppTextStyles.heading3,
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTextStyles.heading3),
                Text(
                  '₹${order.total.toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

