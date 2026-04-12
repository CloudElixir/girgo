import 'package:flutter/material.dart';

/// Off-screen icons so `flutter build web` tree-shaking retains glyphs for the admin shell.
class MaterialIconsKeepalive extends StatelessWidget {
  const MaterialIconsKeepalive({super.key});

  static const List<IconData> _icons = [
    Icons.inventory_2_rounded,
    Icons.receipt_long_rounded,
    Icons.autorenew_rounded,
    Icons.people_alt_rounded,
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.receipt_long,
    Icons.repeat,
    Icons.people_outline,
    Icons.article_outlined,
    Icons.campaign_outlined,
    Icons.grid_view_rounded,
    Icons.local_shipping_outlined,
    Icons.settings_outlined,
    Icons.menu_rounded,
    Icons.notifications_outlined,
    Icons.spa_rounded,
    Icons.keyboard_double_arrow_right_rounded,
    Icons.menu_open_rounded,
    Icons.dashboard_rounded,
    Icons.person_outline_rounded,
    Icons.logout_rounded,
    Icons.keyboard_arrow_down_rounded,
    Icons.trending_up_rounded,
    Icons.trending_down_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (final i in _icons) Icon(i, size: 1)],
    );
  }
}
