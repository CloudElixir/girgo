import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/products.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/cart_icon_button.dart';
import '../utils/data_url_image_decoder.dart';

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
  String? _selectedVariantId;
  late final bool _isMilk;
  late final Product _milk1L;
  late final Product _milkHalfL;
  String _milkPlan = 'one-time'; // 'one-time' | 'monthly-1/2' | 'monthly-1'
  
  @override
  void initState() {
    super.initState();
    _selectedVariantId = widget.product.id;
    _isMilk = widget.product.id == 'milk-1l' || widget.product.id == 'milk-500ml';
    _milk1L = Products.allProducts.firstWhere((p) => p.id == 'milk-1l', orElse: () => widget.product);
    _milkHalfL = Products.allProducts.firstWhere((p) => p.id == 'milk-500ml', orElse: () => widget.product);

    // Set default purchase type based on product
    if (_isMilk) {
      // For milk products: default to One Time Purchase for both 500ml and 1L.
      selectedSubscriptionType = 'Monthly';
      _milkPlan = 'one-time';
      purchaseType = 'one-time';
    } else if (widget.product.isSubscriptionAvailable) {
      purchaseType = 'subscription';
    } else {
      purchaseType = 'one-time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final relatedVariants = _buildRelatedVariants(productsProvider.products);
    if (_selectedVariantId == null || _selectedVariantId!.isEmpty) {
      _selectedVariantId = widget.product.id;
    }

    final Product activeProduct;
    if (!_isMilk) {
      activeProduct = relatedVariants.firstWhere(
        (p) => p.id == _selectedVariantId,
        orElse: () => widget.product,
      );
    } else if (_milkPlan == 'monthly-1/2') {
      activeProduct = _milkHalfL;
    } else if (_milkPlan == 'monthly-1') {
      activeProduct = _milk1L;
    } else {
      // One-time: keep the product size the user opened (500ml vs 1L).
      activeProduct = widget.product;
    }

    final bool isMonthlyMilk = _isMilk && _milkPlan != 'one-time';
    final bool showMilkTabs = _isMilk;

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
                  child: (activeProduct.image.startsWith('http'))
                    ? Image.network(
                        activeProduct.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 60,
                            color: AppColors.textLight,
                          );
                        },
                      )
                    : activeProduct.image.startsWith('data:image')
                        ? Image.memory(
                            DataUrlImageDecoder.decode(activeProduct.image),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image,
                                size: 60,
                                color: AppColors.textLight,
                              );
                            },
                          )
                    : Image.asset(
                        activeProduct.image,
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
                              activeProduct.name,
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
                        (purchaseType == 'subscription' && activeProduct.subscriptionPrice != null)
                            ? '₹${activeProduct.subscriptionPrice!.toInt()}/month'
                            : purchaseType == 'trial'
                                ? '₹150'
                                : '₹${activeProduct.price.toInt()}',
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
                  if (showMilkTabs) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('One Time Purchase • ₹150'),
                          selected: _milkPlan == 'one-time',
                          onSelected: (_) {
                            setState(() {
                              _milkPlan = 'one-time';
                              purchaseType = 'one-time';
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _milkPlan == 'one-time' ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Monthly subscription ½ Litre • ₹1820/month'),
                          selected: _milkPlan == 'monthly-1/2',
                          onSelected: (_) {
                            setState(() {
                              _milkPlan = 'monthly-1/2';
                              purchaseType = 'subscription';
                              selectedSubscriptionType = 'Monthly';
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _milkPlan == 'monthly-1/2' ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Monthly subscription 1 Litre • ₹3500/month'),
                          selected: _milkPlan == 'monthly-1',
                          onSelected: (_) {
                            setState(() {
                              _milkPlan = 'monthly-1';
                              purchaseType = 'subscription';
                              selectedSubscriptionType = 'Monthly';
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _milkPlan == 'monthly-1' ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (!productsProvider.isLoading &&
                      relatedVariants.length > 1) ...[
                    Text('Select Variant', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: relatedVariants.map((variant) {
                        final isSelected = _selectedVariantId == variant.id;
                        String chipPrice = '₹${variant.price.toInt()}';
                        if (variant.subscriptionPrice != null &&
                            variant.subscriptionPrice! > 0 &&
                            (variant.subscriptionPrice! - variant.price).abs() < 1.0) {
                          chipPrice = '₹${variant.price.toInt()}/mo';
                        }
                        return ChoiceChip(
                          label: Text('${variant.quantity} • $chipPrice'),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedVariantId = variant.id;
                              purchaseType = variant.isSubscriptionAvailable &&
                                      variant.subscriptionPrice != null
                                  ? 'subscription'
                                  : 'one-time';
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (!productsProvider.isLoading &&
                      relatedVariants.length <= 1) ...[
                    // Nothing to show: this product has no matching variants in Firestore.
                  ] else if (activeProduct.isSubscriptionAvailable) ...[
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
                          if (activeProduct.id == 'milk-1l')
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
                                Text('Subscribe - ₹${activeProduct.subscriptionPrice!.toInt()}/month'),
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
                    activeProduct.description,
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
                        if (_isMilk) {
                          if (isMonthlyMilk) {
                            await cartProvider.addToCart(
                              activeProduct,
                              quantity: quantity,
                              isSubscription: true,
                              subscriptionType: 'Monthly',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Subscription added to cart!')),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            await cartProvider.addToCart(activeProduct, quantity: quantity);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product added to cart!')),
                              );
                              Navigator.pop(context);
                            }
                          }
                        } else {
                          // Add trial or one-time purchase to cart
                          final shouldSubscribe = purchaseType == 'subscription' &&
                              activeProduct.subscriptionPrice != null;
                          await cartProvider.addToCart(
                            activeProduct,
                            quantity: quantity,
                            isSubscription: shouldSubscribe,
                            subscriptionType: shouldSubscribe ? 'Monthly' : null,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Product added to cart!'),
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
      // Subscription modal removed for milk UX simplicity.
      bottomSheet: null,
    );
  }

  List<Product> _buildRelatedVariants(List<Product> all) {
    if (_isMilk) return [widget.product];
    final current = widget.product;
    final base = _baseName(current.name);
    final sameCategory = all.where((p) => p.category == current.category);
    final variants = sameCategory
        .where((p) => _baseName(p.name) == base)
        .toList();
    if (variants.isEmpty) return [current];
    variants.sort((a, b) => _variantSizeRank(a.quantity).compareTo(
          _variantSizeRank(b.quantity),
        ));
    return variants;
  }

  String _baseName(String s) {
    for (final sep in [' — ', ' – ', ' - ', '—', '–']) {
      final i = s.indexOf(sep);
      if (i > 0) return s.substring(0, i).trim();
    }
    return s.trim();
  }

  int _variantSizeRank(String quantity) {
    final q = quantity.toLowerCase().trim();
    if (q.contains('½') || RegExp(r'\b1\s*/\s*2\b').hasMatch(q)) return 500;
    final ml = RegExp(r'^(\d+(?:\.\d+)?)\s*ml').firstMatch(q);
    if (ml != null) return double.parse(ml.group(1)!).round();
    final l = RegExp(r'^(\d+(?:\.\d+)?)\s*(l|litre|litres|lt)').firstMatch(q);
    if (l != null) return (double.parse(l.group(1)!) * 1000).round();
    final g = RegExp(r'^(\d+(?:\.\d+)?)\s*g').firstMatch(q);
    if (g != null) return double.parse(g.group(1)!).round();
    final kg = RegExp(r'^(\d+(?:\.\d+)?)\s*kg').firstMatch(q);
    if (kg != null) return (double.parse(kg.group(1)!) * 1000).round();
    final n = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(q);
    if (n != null) return double.parse(n.group(1)!).round();
    return 1000000;
  }
}

