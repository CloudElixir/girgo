import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/data_url_image_decoder.dart';
import '../utils/require_auth.dart';

import '../models/product.dart';
import 'product_detail_screen.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_thumbnail.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _categoryDisplayOrder = [
    'milk',
    'ghee',
    'paneer',
    'dhoopa',
    'diyas',
    'gomutra',
    'pachagavya',
    'panchagavya',
    'dung cakes',
    'cow dung cakes',
  ];

  List<Product> get filteredProducts {
    final productsProvider = Provider.of<ProductsProvider>(context);
    var products = productsProvider.getProductsByCategory(selectedCategory);
    
    if (searchQuery.isNotEmpty) {
      products = productsProvider.searchProducts(searchQuery)
          .where((p) => selectedCategory == 'All' || p.category == selectedCategory)
          .toList();
    }
    
    return products;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF0B510E), // Dark green
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'All Products',
              style: AppTextStyles.heading2.copyWith(
                color: const Color(0xFF2D5016),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Product list styled like the screenshot
          Expanded(
            child: Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
                if (productsProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (productsProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${productsProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => productsProvider.loadProducts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                // Group products so variants (sizes) show in a single card
                final Map<String, List<Product>> grouped = {};
                for (final product in filteredProducts) {
                  // For some categories (like Dhoopa) multiple variants may have
                  // slightly different names (e.g. "Herbal Dhoop Sticks" and
                  // "Herbal Dhoop Sticks - Combo Pack"). We group them by
                  // a normalized "base name".
                  final baseName = _getBaseProductName(product);
                  final key = '${product.category}-$baseName';
                  grouped.putIfAbsent(key, () => []).add(product);
                }
                final groups = grouped.values.map((group) {
                  if (group.isEmpty) return group;
                  final cat = group.first.category.toLowerCase();
                  // Ensure variants are shown in logical ascending order.
                  if (cat == 'ghee' || cat == 'milk') {
                    group.sort((a, b) => _quantityToMilliliters(a.quantity)
                        .compareTo(_quantityToMilliliters(b.quantity)));
                  } else if (cat == 'paneer') {
                    group.sort((a, b) => _quantityToGrams(a.quantity)
                        .compareTo(_quantityToGrams(b.quantity)));
                  }
                  return group;
                }).toList();

                int categoryRank(String category) {
                  final c = category.toLowerCase().trim();
                  final idx = _categoryDisplayOrder.indexOf(c);
                  return idx >= 0 ? idx : 999;
                }

                groups.sort((a, b) {
                  if (a.isEmpty || b.isEmpty) return 0;
                  final aOrder =
                      a.map((p) => p.sortOrder ?? (1 << 30)).reduce((x, y) => x < y ? x : y);
                  final bOrder =
                      b.map((p) => p.sortOrder ?? (1 << 30)).reduce((x, y) => x < y ? x : y);
                  if (aOrder != bOrder) return aOrder.compareTo(bOrder);
                  final aRank = categoryRank(a.first.category);
                  final bRank = categoryRank(b.first.category);
                  if (aRank != bRank) return aRank.compareTo(bRank);
                  return a.first.name.toLowerCase().compareTo(
                        b.first.name.toLowerCase(),
                      );
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final productsInGroup = groups[index];
                    return ProductGroupCard(products: productsInGroup);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to normalize product names for grouping variants
String _getBaseProductName(Product product) {
  final cat = product.category.toLowerCase();
  // For Dhoopa, strip anything after " - " (ASCII hyphen).
  if (cat == 'dhoopa') {
    return product.name.split(' - ').first.trim();
  }
  // Milk / ghee / paneer: same listing in Firestore often uses an em dash title;
  // variants must group or every size becomes a separate card.
  if (cat == 'milk' || cat == 'ghee' || cat == 'paneer') {
    final name = product.name;
    for (final sep in [' — ', ' – ', ' - ', '—', '–']) {
      final i = name.indexOf(sep);
      if (i > 0) return name.substring(0, i).trim();
    }
  }
  return product.name;
}

/// Converts a product quantity string to milliliters for sorting purposes.
///
/// Supports formats like "250ml", "500 ml", "1 Litre", "3 Litres", "10lt".
int _quantityToMilliliters(String quantity) {
  final lower = quantity.toLowerCase().trim();

  if (lower.contains('½') ||
      RegExp(r'\b1\s*/\s*2\b').hasMatch(lower) ||
      lower.contains('half')) {
    if (lower.contains('l') ||
        lower.contains('litre') ||
        lower.contains('liter') ||
        lower.contains('ltr')) {
      return 500;
    }
  }

  final mlMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*ml").firstMatch(lower);
  if (mlMatch != null) {
    return (double.parse(mlMatch.group(1)!) * 1).round();
  }

  final litreMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*(l|litre|litres|lt)").firstMatch(lower);
  if (litreMatch != null) {
    return (double.parse(litreMatch.group(1)!) * 1000).round();
  }

  if (RegExp(r'^\s*1\s*/\s*2\s*$').hasMatch(lower) ||
      lower == '½' ||
      (lower.contains('½') && !lower.contains('ml'))) {
    return 500;
  }

  // Fallback: if we can parse a plain number, assume litres.
  final numberMatch = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(lower);
  if (numberMatch != null) {
    return (double.parse(numberMatch.group(1)!) * 1000).round();
  }

  // Unknown format: treat as very large so it appears last.
  return 1000000;
}

int _quantityToGrams(String quantity) {
  final lower = quantity.toLowerCase().trim();
  final gMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*g").firstMatch(lower);
  if (gMatch != null) {
    return (double.parse(gMatch.group(1)!) * 1).round();
  }
  final kgMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*kg").firstMatch(lower);
  if (kgMatch != null) {
    return (double.parse(kgMatch.group(1)!) * 1000).round();
  }
  final numberMatch = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(lower);
  if (numberMatch != null) {
    return double.parse(numberMatch.group(1)!).round();
  }
  return 1000000;
}

/// When one-time and monthly price match, it's a monthly SKU (e.g. ½ litre subscription).
String _variantChipLabel(Product variant) {
  final sub = variant.subscriptionPrice;
  final price = variant.price;
  if (variant.isSubscriptionAvailable && sub != null && sub > 0) {
    if ((price - sub).abs() < 1.0) {
      return '${variant.quantity} • ₹${price.round()}/mo';
    }
  }
  return '${variant.quantity} • ₹${price.round()}';
}

Widget _selectedVariantPriceBlock(Product selectedProduct) {
  const bold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2D5016),
  );
  final sub = selectedProduct.subscriptionPrice;
  final price = selectedProduct.price;
  if (selectedProduct.isSubscriptionAvailable && sub != null && sub > 0) {
    if ((price - sub).abs() < 1.0) {
      return Text('₹${price.round()}/mo', style: bold);
    }
    if (price < sub * 0.4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${price.round()}', style: bold),
          Text(
            'Subscribe: ₹${sub.round()}/mo',
            style: AppTextStyles.caption,
          ),
        ],
      );
    }
  }
  return Text('₹${selectedProduct.price.round()}', style: bold);
}

String _shortProductName(String name) {
  final s = name.trim();
  if (s.length <= 42) return s;
  return '${s.substring(0, 39)}…';
}

bool _isMilkHalfLitreSubscription(Product p) {
  if (p.category.toLowerCase() != 'milk' || !p.isSubscriptionAvailable) {
    return false;
  }
  final q = p.quantity.toLowerCase();
  if (q.contains('500') && (q.contains('ml') || q.contains('milli'))) {
    return true;
  }
  if (q.contains('½') || q.contains('half')) return true;
  if (RegExp(r'1\s*/\s*2').hasMatch(q)) return true;
  return false;
}

class ProductGroupCard extends StatefulWidget {
  final List<Product> products;

  const ProductGroupCard({
    super.key,
    required this.products,
  }) : assert(products.length > 0);

  @override
  State<ProductGroupCard> createState() => _ProductGroupCardState();
}

class _ProductGroupCardState extends State<ProductGroupCard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final baseProduct = widget.products[0];
    final selectedProduct = widget.products[_selectedIndex];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: widget.products[_selectedIndex]),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image with offer tag
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.medium),
                    child: ProductThumbnail(
                      product: baseProduct,
                      imageRaw: baseProduct.image,
                      size: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Product details, variant chips and ADD button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baseProduct.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedProduct.quantity,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Variant chips (size + price)
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: List.generate(
                            widget.products.length,
                            (index) {
                              final variant = widget.products[index];
                              final isSelected = index == _selectedIndex;
                              return ChoiceChip(
                                label: Text(
                                  _variantChipLabel(variant),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0B510E),
                                  ),
                                ),
                                selected: isSelected,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                selectedColor: const Color(0xFF0B510E),
                                backgroundColor: Colors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: const Color(0xFF0B510E)
                                        .withOpacity(0.4),
                                  ),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 0,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _selectedVariantPriceBlock(selectedProduct),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final selectedProduct =
                                      widget.products[_selectedIndex];
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  try {
                                    if (_isMilkHalfLitreSubscription(
                                        selectedProduct)) {
                                      await cartProvider.addToCart(
                                        selectedProduct,
                                        isSubscription: true,
                                        subscriptionType: 'Monthly',
                                      );
                                    } else {
                                      await cartProvider.addToCart(
                                          selectedProduct);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${_shortProductName(selectedProduct.name)} (${selectedProduct.quantity}) added to cart',
                                          ),
                                          duration: const Duration(
                                              milliseconds: 800),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not add to cart: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B510E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.medium),
                    child: (product.image.startsWith('http'))
                        ? Image.network(
                            product.image,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.gray,
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.medium,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 36,
                                  color: AppColors.textLight,
                                ),
                              );
                            },
                          )
                        : product.image.startsWith('data:image')
                            ? Image.memory(
                                DataUrlImageDecoder.decode(product.image),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray,
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.medium,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      size: 36,
                                      color: AppColors.textLight,
                                    ),
                                  );
                                },
                              )
                        : Image.asset(
                            product.image,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.gray,
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.medium,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 36,
                                  color: AppColors.textLight,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Product details and ADD button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.quantity,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.id == 'milk-1l') ...[
                                  Text(
                                    'one time purchase: ${product.price.toInt()}rs',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                  if (product.subscriptionPrice != null)
                                    Text(
                                      'monthly subscription 1 ltr : ${product.subscriptionPrice!.toInt()}',
                                      style: AppTextStyles.caption,
                                    ),
                                ] else if (product.id == 'milk-500ml') ...[
                                  Text(
                                    'monthly subscription 1/2 ltr : ${(product.subscriptionPrice ?? product.price).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '₹${product.price.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                  if (product.subscriptionPrice != null)
                                    Text(
                                      'Subscribe • ₹${product.subscriptionPrice!.toInt()}/month',
                                      style: AppTextStyles.caption,
                                    ),
                                ],
                              ],
                            ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!await ensureSignedIn(context) || !context.mounted) return;
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  if (product.id == 'milk-500ml') {
                                    // Add monthly subscription for 1/2 litre.
                                    await cartProvider.addToCart(
                                      product,
                                      isSubscription: true,
                                      subscriptionType: 'Monthly',
                                    );
                                  } else {
                                    // Default: add as one-time.
                                    await cartProvider.addToCart(product);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} added to cart',
                                        ),
                                        duration:
                                            const Duration(milliseconds: 800),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B510E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

