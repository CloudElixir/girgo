import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class SubscriptionsAdminView extends StatefulWidget {
  const SubscriptionsAdminView({super.key});

  @override
  State<SubscriptionsAdminView> createState() => _SubscriptionsAdminViewState();
}

class _SubscriptionsAdminViewState extends State<SubscriptionsAdminView> {
  String? _selectedStatus;
  final Map<String, Map<String, dynamic>?> _userCache = {};

  Widget _getStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Paused':
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      case 'Cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'Pending':
        color = Colors.blue;
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    
    final userInfo = await FirestoreService.getUserInfo(userId);
    _userCache[userId] = userInfo;
    return userInfo;
  }

  Future<void> _updateStatus(String subscriptionId, String newStatus) async {
    try {
      await FirestoreService.updateSubscriptionStatus(subscriptionId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription status updated to $newStatus')),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allSubscriptions = snapshot.data!;
        
        // Filter by status
        final filteredSubscriptions = _selectedStatus == null
            ? allSubscriptions
            : allSubscriptions.where((sub) => (sub['status'] ?? 'Active') == _selectedStatus).toList();

        // Get unique statuses
        final statuses = allSubscriptions
            .map((s) => s['status']?.toString() ?? 'Active')
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
                    'Subscriptions',
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
            
            // Subscriptions list
            Expanded(
              child: filteredSubscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.repeat_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allSubscriptions.isEmpty
                                ? 'No subscriptions found.'
                                : 'No subscriptions with selected status.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredSubscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = filteredSubscriptions[index];
                        final status = subscription['status'] ?? 'Active';
                        final productName = subscription['productName'] ?? 'Unknown Product';
                        final quantity = subscription['quantity'] ?? 1;
                        final type = subscription['type'] ?? 'Daily';
                        final price = (subscription['price'] as num?)?.toDouble() ?? 0.0;
                        final createdAt = subscription['createdAt'];
                        final dateStr = createdAt != null
                            ? DateFormat('MMM dd, yyyy').format(
                                (createdAt as dynamic).toDate(),
                              )
                            : 'Unknown date';
                        final userId = subscription['userId'] ?? 'Unknown';
                        final nextDelivery = subscription['nextDeliveryDate'];

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: _getStatusChip(status),
                            title: Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$quantity · $type · ₹${price.toStringAsFixed(2)}'),
                                Text(
                                  'User: $userId',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  'Started: $dateStr',
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
                                    // User Information
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: _getUserInfo(userId),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.only(bottom: 16),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Loading user info...'),
                                              ],
                                            ),
                                          );
                                        }
                                        
                                        final userInfo = userSnapshot.data;
                                        if (userInfo != null) {
                                          final userName = userInfo['name'] ?? userInfo['userName'] ?? 'Unknown';
                                          final userEmail = userInfo['email'] ?? userInfo['userEmail'] ?? 'No email';
                                          final userPhone = userInfo['phone'] ?? '';
                                          
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'User Information',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                _buildDetailRow('Name', userName),
                                                _buildDetailRow('Email', userEmail),
                                                if (userPhone.isNotEmpty)
                                                  _buildDetailRow('Phone', userPhone),
                                                _buildDetailRow('User ID', userId),
                                              ],
                                            ),
                                          );
                                        }
                                        
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildDetailRow('User ID', userId),
                                              Text(
                                                'User information not available',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    const Divider(),
                                    
                                    // Subscription Details
                                    _buildDetailRow('Product', productName),
                                    _buildDetailRow('Quantity', quantity.toString()),
                                    _buildDetailRow('Type', type),
                                    _buildDetailRow('Price', '₹${price.toStringAsFixed(2)}'),
                                    _buildDetailRow('Status', status),
                                    if (nextDelivery != null)
                                      _buildDetailRow(
                                        'Next Delivery',
                                        DateFormat('MMM dd, yyyy').format(
                                          (nextDelivery as dynamic).toDate(),
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'Active')
                                          OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                              subscription['id'] as String,
                                              'Paused',
                                            ),
                                            icon: const Icon(Icons.pause),
                                            label: const Text('Pause'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.orange,
                                            ),
                                          ),
                                        if (status == 'Paused') ...[
                                          OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                              subscription['id'] as String,
                                              'Active',
                                            ),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('Resume'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (status == 'Pending') ...[
                                          OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                              subscription['id'] as String,
                                              'Active',
                                            ),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Approve'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        OutlinedButton.icon(
                                          onPressed: () => _updateStatus(
                                            subscription['id'] as String,
                                            'Cancelled',
                                          ),
                                          icon: const Icon(Icons.cancel),
                                          label: const Text('Cancel'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
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
