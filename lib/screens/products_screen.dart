import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import '../widgets/cart_icon_button.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
                final groups = grouped.values.toList();

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
  // For Dhoopa and similar categories, strip anything after " - "
  // so "Herbal Dhoop Sticks - Combo Pack" groups with "Herbal Dhoop Sticks".
  if (product.category.toLowerCase() == 'dhoopa') {
    return product.name.split(' - ').first.trim();
  }
  return product.name;
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
                    child: Image.asset(
                      baseProduct.image,
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
                          baseProduct.quantity,
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
                                  '${variant.quantity} • ₹${variant.price.toInt()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0B510E),
                                  ),
                                ),
                                selected: isSelected,
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
                          children: [
                            Text(
                              '₹${widget.products[_selectedIndex].price.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5016),
                              ),
                            ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final selectedProduct =
                                      widget.products[_selectedIndex];
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  await cartProvider.addToCart(selectedProduct);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${selectedProduct.name} (${selectedProduct.quantity}) added to cart',
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
                    child: Image.asset(
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
                                if (product.id == 'milk-1l')
                                  Text(
                                    'Trial • ₹${product.price.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D5016),
                                    ),
                                  )
                                else
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
                                    'Subscribe • ₹${product.subscriptionPrice!.toInt()}/day',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  await cartProvider.addToCart(product);
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

