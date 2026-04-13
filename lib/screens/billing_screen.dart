import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_service.dart';
import '../utils/require_auth.dart';
import '../utils/payment_platform.dart';
import '../widgets/cart_icon_button.dart';
import 'order_confirmation_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _paymentService = PaymentService();
  bool _hasProcessed = false;
  bool _isProcessing = false;
  Timer? _pinDebounce;
  bool _pinChecking = false;
  /// null = not yet checked or incomplete PIN; true/false after Firestore check (6 digits).
  bool? _pinInServiceArea;
  List<String> _pinDropdownOptions = [];
  bool _pinOptionsLoading = false;
  String? _selectedPincode;

  bool get _usePinDropdown => false;

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers
    _nameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _streetController.addListener(_onFormChanged);
    _cityController.addListener(_onFormChanged);
    _stateController.addListener(_onFormChanged);
    _pincodeController.addListener(_onFormChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await ensureSignedIn(context);
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).pop();
        return;
      }
      final pins = await FirestoreService.getServiceablePinDropdownOptions();
      if (!mounted) return;
      setState(() {
        _pinDropdownOptions = pins;
        _pinOptionsLoading = false;
      });
      _onFormChanged();
    });
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
    _schedulePinServiceCheck();
    _checkAndProcessPayment();
  }

  void _schedulePinServiceCheck() {
    if (_pinOptionsLoading) return;

    if (_usePinDropdown) {
      _pinDebounce?.cancel();
      final pin = _pincodeController.text.trim();
      if (pin.length == 6 && _pinDropdownOptions.contains(pin)) {
        if (_pinInServiceArea != true || _pinChecking) {
          setState(() {
            _pinChecking = false;
            _pinInServiceArea = true;
          });
        }
      } else if (_pinInServiceArea != null || _pinChecking) {
        setState(() {
          _pinChecking = false;
          _pinInServiceArea = null;
        });
      }
      return;
    }

    final pin = _pincodeController.text.trim();
    _pinDebounce?.cancel();
    if (pin.length != 6) {
      if (_pinChecking || _pinInServiceArea != null) {
        setState(() {
          _pinChecking = false;
          _pinInServiceArea = null;
        });
      }
      return;
    }

    setState(() {
      _pinChecking = true;
      _pinInServiceArea = null;
    });

    _pinDebounce = Timer(const Duration(milliseconds: 450), () async {
      final ok = await FirestoreService.isPincodeInServiceArea(pin);
      if (!mounted) return;
      if (_pincodeController.text.trim() != pin) return;
      setState(() {
        _pinChecking = false;
        _pinInServiceArea = ok;
      });
      if (ok) {
        _checkAndProcessPayment();
      }
    });
  }

  void _checkAndProcessPayment() {
    // Prevent multiple payment attempts
    if (_hasProcessed || _isProcessing) return;

    // Check if all required fields are filled and valid
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (pincode.length == 6 && (_pinChecking || _pinInServiceArea != true)) {
      return;
    }

    // Validate all required fields
    if (name.isNotEmpty &&
        phone.length == 10 &&
        street.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        pincode.length == 6) {
      // Validate form before processing payment
      if (_formKey.currentState?.validate() ?? false) {
        _hasProcessed = true;
        // Small delay to ensure UI is updated
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _handlePayment();
        });
      }
    }
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

    final pincode = _pincodeController.text.trim();
    final pinAllowed = await FirestoreService.isPincodeInServiceArea(pincode);
    if (!pinAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FirestoreService.serviceAreaMessage)),
      );
      setState(() {
        _hasProcessed = false;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final street = _streetController.text.trim();
      final landmark = _landmarkController.text.trim();
      final city = _cityController.text.trim();
      final state = _stateController.text.trim();
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
          contact: phone,
          email: FirebaseService.auth?.currentUser?.email,
          name: name,
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
        'name': name,
        'phone': phone,
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
  void dispose() {
    _pinDebounce?.cancel();
    _nameController.removeListener(_onFormChanged);
    _phoneController.removeListener(_onFormChanged);
    _streetController.removeListener(_onFormChanged);
    _cityController.removeListener(_onFormChanged);
    _stateController.removeListener(_onFormChanged);
    _pincodeController.removeListener(_onFormChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF0B510E),
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final pin = _usePinDropdown
              ? (_selectedPincode ?? '').trim()
              : _pincodeController.text.trim();
          final payBlocked = _pinOptionsLoading ||
              (pin.length == 6 && (_pinChecking || _pinInServiceArea != true));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact
                  const Text('Contact', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 10) {
                        return 'Please enter valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Billing address
                  const Text('Billing address', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.map),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_pinOptionsLoading) ...[
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Pincode *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      child: const SizedBox(
                        height: 24,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_usePinDropdown) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedPincode,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      decoration: const InputDecoration(
                        labelText: 'Pincode *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                        hintText: 'Select PIN code',
                      ),
                      items: _pinDropdownOptions
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(p, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedPincode = v;
                          _pincodeController.text = v ?? '';
                          _pinChecking = false;
                          _pinInServiceArea = v != null ? true : null;
                        });
                        _checkAndProcessPayment();
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please select a pincode';
                        }
                        return null;
                      },
                    ),
                    if (_selectedPincode != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delivery available for this PIN',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.pin),
                        suffixIcon: pin.length == 6
                            ? (_pinChecking
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : Icon(
                                    _pinInServiceArea == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _pinInServiceArea == true
                                        ? const Color(0xFF0B510E)
                                        : Colors.red.shade700,
                                  ))
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 6) {
                          return 'Please enter valid 6-digit pincode';
                        }
                        if (_pinInServiceArea == false) {
                          return FirestoreService.serviceAreaMessage;
                        }
                        return null;
                      },
                    ),
                    if (pin.length == 6 &&
                        !_pinChecking &&
                        _pinInServiceArea == true) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delivery available for this PIN',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (pin.length == 6 &&
                        !_pinChecking &&
                        _pinInServiceArea == false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Shipping not available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB00020),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your order cannot be shipped to the selected address. Review your address and try again, or select a different pincode.',
                              style: TextStyle(
                                color: Color(0xFFB00020),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // Delivery and payment
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery and payment', style: AppTextStyles.heading3),
                        const SizedBox(height: AppSpacing.md),
                        _buildSummaryRow('Subtotal', cartProvider.totals['subtotal']!),
                        if ((cartProvider.totals['deliveryFee'] ?? 0) > 0)
                          _buildSummaryRow('Delivery Fee', cartProvider.totals['deliveryFee']!),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: AppTextStyles.heading3),
                            Text(
                              '₹${cartProvider.totals['total']!.toInt()}',
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
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Continue to Payment Button (fallback if auto-payment doesn't trigger)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || payBlocked)
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _handlePayment();
                              }
                            },
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
            ),
          );
        },
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

