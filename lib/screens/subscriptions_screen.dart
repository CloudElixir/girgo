import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../constants/theme.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_service.dart';
import '../constants/products.dart';
import 'package:intl/intl.dart';
import '../utils/require_auth.dart';
import '../widgets/cart_icon_button.dart';
import '../utils/data_url_image_decoder.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Sync local subscriptions to Firestore on first load
    _syncSubscriptionsToFirestore();
  }

  Future<void> _loadSubscriptions() async {
    // Sync local subscriptions to Firestore (one-time migration)
    await _syncSubscriptionsToFirestore();
  }

  Future<void> _syncSubscriptionsToFirestore() async {
    try {
      // Get user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        return;
      }

      // Get all local subscriptions
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.loadSubscriptions();
      final localSubscriptions = subscriptionProvider.subscriptions;
      
      // Sync each subscription to Firestore (one-time migration)
      for (final subscription in localSubscriptions) {
        try {
          // Migrate to Firestore (the function checks for duplicates internally)
          await FirestoreService.migrateSubscriptionToFirestore(
            userId: userId,
            productId: subscription.productId,
            productName: subscription.productName,
            productImage: subscription.productImage,
            quantity: subscription.quantity,
            price: subscription.price,
            type: subscription.type,
            status: subscription.status,
            createdAt: subscription.createdAt,
            nextDeliveryDate: _parseNextDeliveryDate(subscription.nextDelivery),
          );
        } catch (e) {
          // Ignore if already exists (migrateSubscriptionToFirestore handles this)
          print('⚠️ Subscription sync: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing subscriptions: $e');
    }
  }

  DateTime? _parseNextDeliveryDate(String dateStr) {
    try {
      // Format: "DD/MM/YYYY"
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Paused':
        return AppColors.warning;
      case 'Pending':
        return Colors.orange; // Orange for pending/waiting status
      default:
        return AppColors.error;
    }
  }

  Future<void> _pauseSubscription(String subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Subscription'),
        content: const Text('Are you sure you want to pause this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService.updateSubscriptionStatus(subscriptionId, 'Paused');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription paused')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pause subscription: $e')),
          );
        }
      }
    }
  }

  Future<void> _resumeSubscription(String subscriptionId) async {
    try {
      await FirestoreService.updateSubscriptionStatus(subscriptionId, 'Active');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription resumed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resume subscription: $e')),
        );
      }
    }
  }

  Future<void> _cancelSubscription(String subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel this subscription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService.updateSubscriptionStatus(subscriptionId, 'Cancelled');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel subscription: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, userIdSnapshot) {
          if (!userIdSnapshot.hasData || userIdSnapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 56, color: AppColors.textLight),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sign in to view and manage your subscriptions',
                      style: AppTextStyles.heading3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => ensureSignedIn(context),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final userId = userIdSnapshot.data!;
          
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getUserSubscriptions(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final subscriptionsData = snapshot.data!;
          
          // Convert Firestore data to Subscription objects
          final subscriptions = subscriptionsData.map((data) {
            final createdAt = data['createdAt'] as Timestamp?;
            final nextDelivery = data['nextDeliveryDate'] as Timestamp?;
            
            return Subscription(
              id: data['id'] as String? ?? '',
              productId: data['productId'] as String? ?? '',
              productName: data['productName'] as String? ?? '',
              productImage: data['productImage'] as String? ?? '',
              quantity: (data['quantity'] as num?)?.toInt() ?? 1,
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              type: data['type'] as String? ?? 'Daily',
              status: data['status'] as String? ?? 'Pending',
              nextDelivery: nextDelivery != null
                  ? DateFormat('dd/MM/yyyy').format(nextDelivery.toDate())
                  : DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 1))),
              createdAt: createdAt?.toDate() ?? DateTime.now(),
            );
          }).toList();
          
          if (subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.repeat_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('No active subscriptions', style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Subscribe to products for regular deliveries and save more!',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadSubscriptions,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: AppColors.gray,
                                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                              child: (subscription.productImage.startsWith('http'))
                                                ? Image.network(
                                                    subscription.productImage,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(Icons.image, color: AppColors.textLight);
                                                    },
                                                  )
                                                : subscription.productImage.startsWith('data:image')
                                                    ? Image.memory(
                                                        DataUrlImageDecoder.decode(subscription.productImage),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return const Icon(Icons.image, color: AppColors.textLight);
                                                        },
                                                      )
                                                : Image.asset(
                                                    subscription.productImage,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(Icons.image, color: AppColors.textLight);
                                                    },
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subscription.productName,
                                                style: AppTextStyles.heading3,
                                              ),
                                              Text(
                                                '${subscription.quantity} • ${subscription.type}',
                                                style: AppTextStyles.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(subscription.status),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                    ),
                                    child: Text(
                                      subscription.status,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (subscription.status == 'Pending') ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          'Waiting for payment approval',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textLight),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Next Delivery: ${subscription.nextDelivery}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    const Icon(Icons.currency_rupee, size: 16, color: AppColors.textLight),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '₹${subscription.price.toInt()} per delivery',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (subscription.status == 'Active')
                                    TextButton.icon(
                                      onPressed: () => _pauseSubscription(subscription.id),
                                      icon: const Icon(Icons.pause, size: 16),
                                      label: const Text('Pause'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                                    ),
                                  if (subscription.status == 'Paused')
                                    TextButton.icon(
                                      onPressed: () => _resumeSubscription(subscription.id),
                                      icon: const Icon(Icons.play_arrow, size: 16),
                                      label: const Text('Resume'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.success),
                                    ),
                                  if (subscription.status != 'Cancelled' && subscription.status != 'Pending')
                                    TextButton.icon(
                                      onPressed: () => _cancelSubscription(subscription.id),
                                      icon: const Icon(Icons.cancel, size: 16),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                    ),
                                  if (subscription.status == 'Pending')
                                    TextButton.icon(
                                      onPressed: () => _cancelSubscription(subscription.id),
                                      icon: const Icon(Icons.cancel, size: 16),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
          },
        );
        },
      ),
    );
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try Firebase Auth UID first (most reliable)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final uid = firebaseUser.uid;
      final email = firebaseUser.email;
      print('🔍 Firebase Auth - UID: $uid, Email: $email');
      
      // Try UID first
      return uid;
    }
    
    // Fallback to SharedPreferences
    final userId = prefs.getString('user');
    final userEmail = prefs.getString('userEmail');
    
    print('🔍 SharedPreferences - userId: $userId, userEmail: $userEmail');
    
    // If userId looks like an email, use it
    if (userId != null && userId.isNotEmpty) {
      if (userId.contains('@')) {
        print('✅ Using email as userId: $userId');
        return userId;
      } else {
        print('✅ Using UID as userId: $userId');
        return userId;
      }
    }
    
    // Last resort: use email
    if (userEmail != null && userEmail.isNotEmpty) {
      print('✅ Using userEmail: $userEmail');
      return userEmail;
    }
    
    print('⚠️ No user ID found');
    return null;
  }

}

