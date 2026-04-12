import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class OrdersAdminView extends StatefulWidget {
  const OrdersAdminView({super.key});

  @override
  State<OrdersAdminView> createState() => _OrdersAdminViewState();
}

class _OrdersAdminViewState extends State<OrdersAdminView> {
  String? _selectedStatus;

  Widget _getStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Delivered':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Shipped':
        color = Colors.blue;
        icon = Icons.local_shipping;
        break;
      case 'Confirmed':
        color = Colors.orange;
        icon = Icons.check;
        break;
      case 'Paid':
        color = Colors.teal;
        icon = Icons.payments_outlined;
        break;
      case 'Cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.pending;
    }
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _showTrackingNoteDialog(Map<String, dynamic> order) async {
    final orderId = order['id'] as String;
    final controller = TextEditingController(
      text: (order['trackingNote'] ?? '').toString(),
    );
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Customer tracking message'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. Rider will call from 98xxxxxx. ETA 6 PM',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      );
      if (saved != true || !mounted) return;
      try {
        final text = controller.text.trim();
        await FirestoreService.updateOrderTrackingNote(
          orderId,
          text.isEmpty ? null : text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tracking message saved — visible in app')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await FirestoreService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  void _showStatusDialog(String orderId, String currentStatus) {
    final statuses = ['Pending', 'Paid', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isCurrent = status == currentStatus;
            return ListTile(
              leading: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
              title: Text(status),
              onTap: isCurrent
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updateStatus(orderId, status);
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allOrders = snapshot.data!;
        
        // Filter by status
        final filteredOrders = _selectedStatus == null
            ? allOrders
            : allOrders.where((order) => (order['status'] ?? 'Pending') == _selectedStatus).toList();

        // Get unique statuses
        final statuses = allOrders
            .map((o) => o['status']?.toString() ?? 'Pending')
            .toSet()
            .toList()
          ..sort();

        return Column(
          children: [
            // Header with filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    hint: const Text('All Statuses'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...statuses.map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedStatus = value),
                  ),
                ],
              ),
            ),
            
            // Orders list
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allOrders.isEmpty
                                ? 'No orders found.'
                                : 'No orders with selected status.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final status = order['status'] ?? 'Pending';
                        final createdAt = order['createdAt'];
                        final dateStr = createdAt != null
                            ? DateFormat('MMM dd, yyyy HH:mm').format(
                                (createdAt as dynamic).toDate(),
                              )
                            : 'Unknown date';
                        final total = order['total'] ?? 0.0;
                        final items = order['items'] as List? ?? [];
                        final userId = order['userId'] ?? 'Unknown';
                        final address = order['deliveryAddress'] ?? {};
                        final paymentMethod = order['paymentMethod'] ?? 'Unknown';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: _getStatusChip(status),
                            title: Text(
                              'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹${total.toStringAsFixed(2)} · $dateStr'),
                                if (address['name'] != null)
                                  Text(
                                    '${address['name']} · ${address['phone'] ?? ''}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Items
                                    const Text(
                                      'Items:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...items.map((item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item['productName'] ?? 'Unknown'} x${item['quantity'] ?? 1}',
                                                ),
                                              ),
                                              Text(
                                                '₹${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        )),
                                    const Divider(),
                                    
                                    // Order Details
                                    _buildDetailRow('Status', status),
                                    _buildDetailRow('Total', '₹${total.toStringAsFixed(2)}'),
                                    _buildDetailRow('Payment Method', paymentMethod),
                                    if (address['address'] != null)
                                      _buildDetailRow('Address', address['address']),
                                    if (address['city'] != null)
                                      _buildDetailRow('City', address['city']),
                                    if (address['pincode'] != null)
                                      _buildDetailRow('Pincode', address['pincode']),
                                    if (order['trackingNote'] != null &&
                                        order['trackingNote'].toString().isNotEmpty)
                                      _buildDetailRow(
                                        'App tracking note',
                                        order['trackingNote'].toString(),
                                      ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _showTrackingNoteDialog(order),
                                          icon: const Icon(Icons.edit_note),
                                          label: const Text('Tracking note'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _showStatusDialog(order['id'] as String, status),
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Change Status'),
                                        ),
                                        const SizedBox(width: 8),
                                        if (status == 'Pending')
                                          ElevatedButton(
                                            onPressed: () => _updateStatus(order['id'] as String, 'Confirmed'),
                                            child: const Text('Confirm'),
                                          ),
                                        if (status == 'Confirmed')
                                          ElevatedButton(
                                            onPressed: () => _updateStatus(order['id'] as String, 'Shipped'),
                                            child: const Text('Ship'),
                                          ),
                                        if (status == 'Shipped')
                                          ElevatedButton(
                                            onPressed: () => _updateStatus(order['id'] as String, 'Delivered'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            child: const Text('Mark Delivered'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
