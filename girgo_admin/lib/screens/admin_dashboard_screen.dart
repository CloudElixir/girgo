import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import '../widgets/dashboard/admin_sidebar.dart';
import '../widgets/dashboard/admin_top_bar.dart';
import '../widgets/dashboard/page_keep_alive.dart';
import 'dashboard_overview.dart';
import 'views/products_admin_view.dart';
import 'views/orders_admin_view.dart';
import 'views/subscriptions_admin_view.dart';
import 'views/users_admin_view.dart';
import 'views/home_offers_admin_view.dart';
import 'views/blogs_admin_view.dart';
import 'views/settings_admin_view.dart';
import 'views/home_featured_admin_view.dart';
import 'views/delivery_zones_admin_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  late final List<_AdminSection> _sections = [
    _AdminSection(
      label: 'Dashboard',
      subtitle: 'Real-time metrics & KPIs',
      icon: Icons.dashboard_outlined,
      builder: (context) => const DashboardOverview(),
    ),
    _AdminSection(
      label: 'Products',
      subtitle: 'Catalog & inventory',
      icon: Icons.inventory_2_outlined,
      builder: (context) => const ProductsAdminView(),
    ),
    _AdminSection(
      label: 'Orders',
      subtitle: 'Fulfillment & history',
      icon: Icons.receipt_long,
      builder: (context) => const OrdersAdminView(),
    ),
    _AdminSection(
      label: 'Subscriptions',
      subtitle: 'Recurring plans & status',
      icon: Icons.repeat,
      builder: (context) => const SubscriptionsAdminView(),
    ),
    _AdminSection(
      label: 'Users',
      subtitle: 'Accounts & roles',
      icon: Icons.people_outline,
      builder: (context) => const UsersAdminView(),
    ),
    _AdminSection(
      label: 'Blogs',
      subtitle: 'Content & articles',
      icon: Icons.article_outlined,
      builder: (context) => const BlogsAdminView(),
    ),
    _AdminSection(
      label: 'Home Offers',
      subtitle: 'Promos & banners',
      icon: Icons.campaign_outlined,
      builder: (context) => const HomeOffersAdminView(),
    ),
    _AdminSection(
      label: 'Home · Features',
      subtitle: 'Featured tiles on home',
      icon: Icons.grid_view_rounded,
      builder: (context) => const HomeFeaturedAdminView(),
    ),
    _AdminSection(
      label: 'Delivery zones',
      subtitle: 'Shipping regions',
      icon: Icons.local_shipping_outlined,
      builder: (context) => const DeliveryZonesAdminView(),
    ),
    _AdminSection(
      label: 'Settings',
      subtitle: 'Store configuration',
      icon: Icons.settings_outlined,
      builder: (context) => const SettingsAdminView(),
    ),
  ];

  /// Dashboard (index 0) is not keep-alive so Firestore KPI streams pause off-tab.
  late final List<Widget> _pages = List.generate(_sections.length, (i) {
    final child = Builder(builder: _sections[i].builder);
    return i == 0 ? child : KeepAlivePage(child: child);
  });

  List<AdminNavItem> get _navItems =>
      [for (final s in _sections) (label: s.label, icon: s.icon)];

  void _onSectionSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _selectFromDrawer(int index) {
    _onSectionSelected(index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = _sections[_selectedIndex];
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    final mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          AdminSidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            onSelect: _onSectionSelected,
            collapsed: _sidebarCollapsed,
            onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
        Expanded(
          child: ColoredBox(
            color: scheme.surfaceContainer,
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      drawer: desktop
          ? null
          : Drawer(
              backgroundColor: GirgoBrand.white,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [GirgoBrand.green, GirgoBrand.greenMid],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Girgo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    letterSpacing: -0.4,
                                    color: GirgoBrand.black,
                                  ),
                                ),
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: GirgoBrand.blackMuted,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: GirgoBrand.borderLight),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final s = _sections[index];
                          final selected = index == _selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: selected ? GirgoBrand.greenSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: selected
                                        ? GirgoBrand.green.withValues(alpha: 0.35)
                                        : Colors.transparent,
                                  ),
                                ),
                                leading: Icon(
                                  s.icon,
                                  color: selected ? GirgoBrand.green : GirgoBrand.blackMuted,
                                ),
                                title: Text(
                                  s.label,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                    color: selected ? GirgoBrand.green : GirgoBrand.black,
                                  ),
                                ),
                                onTap: () => _selectFromDrawer(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            sectionTitle: current.label,
            subtitle: current.subtitle,
            compact: !desktop,
          ),
          Expanded(child: mainRow),
        ],
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.label,
    required this.icon,
    required this.builder,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final String? subtitle;
}
