import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  late final List<_AdminSection> _sections = [
    _AdminSection(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      builder: (context) => const ProductsAdminView(),
    ),
    _AdminSection(
      label: 'Home Offers',
      icon: Icons.campaign_outlined,
      builder: (context) => const HomeOffersAdminView(),
    ),
    _AdminSection(
      label: 'Orders',
      icon: Icons.receipt_long,
      builder: (context) => const PlaceholderCenter(
        title: 'Orders',
        message: 'Orders view coming soon.',
      ),
    ),
  ];

  void _onSectionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = _sections[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${currentSection.label}'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final navigation = NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onSectionSelected,
            labelType: isWide ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            destinations: _sections
                .map(
                  (section) => NavigationRailDestination(
                    icon: Icon(section.icon),
                    label: Text(section.label),
                  ),
                )
                .toList(),
          );

          if (isWide) {
            return Row(
              children: [
                navigation,
                const VerticalDivider(width: 1),
                Expanded(child: currentSection.builder(context)),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;
                    final isSelected = index == _selectedIndex;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _onSectionSelected(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              section.icon,
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              section.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: currentSection.builder(context)),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

class ProductsAdminView extends StatefulWidget {
  const ProductsAdminView({super.key});

  @override
  State<ProductsAdminView> createState() => _ProductsAdminViewState();
}

class _ProductsAdminViewState extends State<ProductsAdminView> {
  Future<void> _toggleProduct(String productId, bool isActive) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService.setProductActiveState(productId, !isActive);
      messenger.showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Product disabled' : 'Product enabled'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(message: 'Error loading products: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        if (products.isEmpty) {
          return const PlaceholderCenter(
            title: 'No products yet',
            message: 'Run migration or add products manually.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];
            final isActive = product['isActive'] == true;
            return Card(
              child: ListTile(
                title: Text(product['name'] ?? 'Unnamed product'),
                subtitle: Text(
                  [
                    product['category'],
                    '₹${product['price']}',
                    if (isActive) 'Active' else 'Inactive',
                  ].whereType<String>().join(' · '),
                ),
                trailing: Switch(
                  value: isActive,
                  onChanged: (_) => _toggleProduct(product['id'] as String, isActive),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HomeOffersAdminView extends StatelessWidget {
  const HomeOffersAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllHomeOffers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(message: 'Error loading offers: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final offers = snapshot.data!;
        if (offers.isEmpty) {
          return const PlaceholderCenter(
            title: 'No offers configured',
            message: 'Use Firestore to create an offer or add one via code.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            final isActive = offer['isActive'] == true;
            return Card(
              child: ListTile(
                title: Text(offer['title'] ?? 'Untitled'),
                subtitle: Text(offer['subtitle'] ?? ''),
                trailing: Chip(
                  label: Text(isActive ? 'Active' : 'Inactive'),
                  backgroundColor: isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PlaceholderCenter extends StatelessWidget {
  const PlaceholderCenter({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


