import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/dashboard/dashboard_stat_card.dart';

/// Main KPI dashboard — premium stat cards with live Firestore streams.
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  static const List<Color> _accents = [
    GirgoBrand.green,
    GirgoBrand.greenMid,
    GirgoBrand.greenMuted,
    GirgoBrand.blackMuted,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateFormat.MMMd().format(DateTime.now());

    return Stack(
      children: [
        Positioned(
          right: -80,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    GirgoBrand.green.withValues(alpha: 0.08),
                    GirgoBrand.green.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -40,
          top: 120,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    GirgoBrand.greenMid.withValues(alpha: 0.06),
                    GirgoBrand.greenMid.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: GirgoBrand.greenSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: GirgoBrand.green.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: GirgoBrand.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live data',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: GirgoBrand.green,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        today,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Overview',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -1.1,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Key metrics synced from Firestore — products, orders, subscriptions, and customers.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onSurface.withValues(alpha: 0.48),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final columns = w >= 1100
                          ? 4
                          : w >= 700
                              ? 2
                              : 1;
                      const gap = 20.0;
                      final cardW = (w - gap * (columns - 1)) / columns;

                      Widget slot(Widget child) => SizedBox(width: cardW, child: child);

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          slot(
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: FirestoreService.getAllProducts(),
                              builder: (context, snapshot) {
                                final loading = !snapshot.hasData && !snapshot.hasError;
                                final n = snapshot.hasData ? snapshot.data!.length : 0;
                                return DashboardStatCard(
                                  title: 'Total products',
                                  icon: Icons.inventory_2_rounded,
                                  accent: _accents[0],
                                  isLoading: loading,
                                  value: n,
                                );
                              },
                            ),
                          ),
                          slot(
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: FirestoreService.getAllOrders(),
                              builder: (context, snapshot) {
                                final loading = !snapshot.hasData && !snapshot.hasError;
                                final n = snapshot.hasData ? snapshot.data!.length : 0;
                                return DashboardStatCard(
                                  title: 'Total orders',
                                  icon: Icons.receipt_long_rounded,
                                  accent: _accents[1],
                                  isLoading: loading,
                                  value: n,
                                );
                              },
                            ),
                          ),
                          slot(
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: FirestoreService.getAllSubscriptions(),
                              builder: (context, snapshot) {
                                final loading = !snapshot.hasData && !snapshot.hasError;
                                final n = snapshot.hasData
                                    ? snapshot.data!.where((s) => s['status'] == 'Active').length
                                    : 0;
                                return DashboardStatCard(
                                  title: 'Active subscriptions',
                                  icon: Icons.autorenew_rounded,
                                  accent: _accents[2],
                                  isLoading: loading,
                                  value: n,
                                );
                              },
                            ),
                          ),
                          slot(
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: FirestoreService.getAllUsers(),
                              builder: (context, snapshot) {
                                final loading = !snapshot.hasData && !snapshot.hasError;
                                final n = snapshot.hasData ? snapshot.data!.length : 0;
                                return DashboardStatCard(
                                  title: 'Registered users',
                                  icon: Icons.people_alt_rounded,
                                  accent: _accents[3],
                                  isLoading: loading,
                                  value: n,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
