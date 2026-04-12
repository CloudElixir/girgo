import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_service.dart';
import '../utils/payment_platform.dart';
import '../widgets/cart_icon_button.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> billingData;

  const PaymentScreen({super.key, required this.billingData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final totals = cartProvider.totals;

    if (cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add products to your cart before paying.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final street = widget.billingData['street'] ?? '';
      final landmark = widget.billingData['landmark'] ?? '';
      final city = widget.billingData['city'] ?? '';
      final state = widget.billingData['state'] ?? '';
      final pincode = widget.billingData['pincode'] ?? '';
      final formattedLandmark = landmark.isNotEmpty ? '$landmark, ' : '';
      final address = '$street, $formattedLandmark$city, $state - $pincode';

      if (!isRazorpayCheckoutSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Razorpay payment works only on Android/iOS builds. Please test on a device or emulator.',
            ),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      String paymentId;
      const paymentMethod = 'Razorpay';

      try {
        paymentId = await _paymentService.initiatePayment(
          amount: totals['total'] ?? 0,
          description: 'Girgo Order Payment',
          contact: widget.billingData['phone'],
          email: FirebaseService.auth?.currentUser?.email,
          name: widget.billingData['name'],
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Resolve user ID
      String? userId;
      if (FirebaseService.auth?.currentUser != null) {
        userId = FirebaseService.auth!.currentUser!.uid;
      } else {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user');
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final orderItems = cartProvider.cartItems.map((item) => {
            'productId': item.product.id,
            'productName': item.product.name,
            'quantity': item.quantity,
            'price': item.isSubscription && item.product.subscriptionPrice != null
                ? item.product.subscriptionPrice!
                : item.product.price,
          }).toList();

      final deliveryAddress = {
        'name': widget.billingData['name'] ?? '',
        'phone': widget.billingData['phone'] ?? '',
        'address': address,
        'street': street,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
      };

      String? orderId;
      try {
        orderId = await FirestoreService.createOrder(
          userId: userId,
          items: orderItems,
          deliveryAddress: deliveryAddress,
          total: totals['total'] ?? 0,
          paymentMethod: paymentMethod,
          paymentId: paymentId,
          status: 'Paid',
        );
      } catch (e) {
        debugPrint('❌ Firestore Order creation failed: $e');
      }

      final subscriptionItems = cartProvider.cartItems.where((item) => item.isSubscription).toList();
      final orderTotal = totals['total'] ?? 0;
      final hasSubscriptions = subscriptionItems.isNotEmpty;

      for (var item in subscriptionItems) {
        if (item.subscriptionType != null) {
          await subscriptionProvider.addSubscription(
            product: item.product,
            quantity: item.quantity,
            type: item.subscriptionType!,
            status: 'Active',
          );

          try {
            final subscriptionPrice = item.product.subscriptionPrice ?? item.product.price;
            await FirestoreService.createSubscription(
              userId: userId,
              productId: item.product.id,
              productName: item.product.name,
              productImage: item.product.image,
              quantity: item.quantity,
              price: subscriptionPrice,
              type: item.subscriptionType!,
              status: 'Active',
              initialPaymentId: paymentId,
              recurringBilling: 'manual',
            );
          } catch (e) {
            debugPrint('❌ Firestore Subscription creation failed: $e');
          }
        }
      }

      await cartProvider.clearCart();

      if (!mounted) return;
      
      // Navigate to order confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderId: orderId ?? 'N/A',
            paymentId: paymentId,
            orderItems: orderItems,
            deliveryAddress: deliveryAddress,
            total: orderTotal,
            paymentMethod: paymentMethod,
            hasSubscriptions: hasSubscriptions,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF0B510E),
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartItems.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textLight),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Your cart is empty',
                      style: AppTextStyles.heading3,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text('Add a product and try again.'),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(cartProvider),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B510E),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: AppColors.white)
                        : const Text(
                            'Proceed to Payment',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow('Subtotal', cartProvider.totals['subtotal'] ?? 0),
          if ((cartProvider.totals['deliveryFee'] ?? 0) > 0)
            _buildSummaryRow('Delivery Fee', cartProvider.totals['deliveryFee'] ?? 0),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: AppTextStyles.heading3),
              Text(
                '₹${(cartProvider.totals['total'] ?? 0).toInt()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B510E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text('₹${value.toInt()}', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

