import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/products.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_icon_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String purchaseType = 'subscription'; // 'trial', 'subscription', or 'one-time'
  bool showSubscriptionModal = false;
  String? selectedSubscriptionType;
  
  @override
  void initState() {
    super.initState();
    // Set default purchase type based on product
    if (widget.product.isSubscriptionAvailable) {
      if (widget.product.id == 'milk-1l') {
        purchaseType = 'trial'; // Default to trial for 1 liter milk
      } else {
        purchaseType = 'subscription'; // Default to subscription for other products
      }
    } else {
      purchaseType = 'one-time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Product Details'),
        actions: const [
          CartIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Product Image
            Container(
              width: double.infinity,
              height: 350,
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  widget.product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image,
                      size: 60,
                      color: AppColors.textLight,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: AppTextStyles.heading1,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Girgo',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        purchaseType == 'subscription' && widget.product.subscriptionPrice != null
                            ? '₹${widget.product.subscriptionPrice!.toInt()}/day'
                            : purchaseType == 'trial'
                                ? '₹150'
                                : '₹${widget.product.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Rating with 5 stars
                  Row(
                    children: [
                      ...List.generate(5, (index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      )),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        '5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Purchase Type Dropdown (if subscription is available)
                  if (widget.product.isSubscriptionAvailable) ...[
                    Text('Purchase Type', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      ),
                      child: DropdownButton<String>(
                        value: purchaseType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [
                          // Trial option (only for 1 liter milk)
                          if (widget.product.id == 'milk-1l')
                            DropdownMenuItem(
                              value: 'trial',
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, size: 20, color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Trial (1 time) - ₹150'),
                                ],
                              ),
                            ),
                          DropdownMenuItem(
                            value: 'subscription',
                            child: Row(
                              children: [
                                const Icon(Icons.repeat, size: 20, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Subscribe - ₹${widget.product.subscriptionPrice!.toInt()}/day'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            purchaseType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Description',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Quantity', style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            if (quantity > 1) quantity--;
                          });
                        },
                      ),
                      Text(
                        '$quantity',
                        style: AppTextStyles.heading3,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Order Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        if (purchaseType == 'subscription' && widget.product.isSubscriptionAvailable) {
                          // Show subscription modal for subscription type
                          setState(() {
                            showSubscriptionModal = true;
                          });
                        } else {
                          // Add trial or one-time purchase to cart
                          final price = purchaseType == 'trial' ? 150.0 : widget.product.price;
                          await cartProvider.addToCart(widget.product, quantity: quantity);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(purchaseType == 'trial' 
                                    ? 'Trial product added to cart!' 
                                    : 'Product added to cart!'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        ),
                      ),
                      child: const Text(
                        'Order Now',
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
          ],
        ),
      ),
      // Subscription Modal
      bottomSheet: showSubscriptionModal
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Choose Subscription Plan', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.md),
                  ...['Daily', 'Weekly', 'Monthly'].map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        title: Text(type),
                        selected: selectedSubscriptionType == type,
                        selectedTileColor: AppColors.primary.withOpacity(0.1),
                        onTap: () {
                          setState(() {
                            selectedSubscriptionType = type;
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              showSubscriptionModal = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedSubscriptionType == null
                              ? null
                              : () async {
                                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                  await cartProvider.addToCart(
                                    widget.product,
                                    quantity: quantity,
                                    isSubscription: true,
                                    subscriptionType: selectedSubscriptionType!,
                                  );
                                  if (context.mounted) {
                                    setState(() {
                                      showSubscriptionModal = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Subscription added to cart!')),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Subscribe'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

