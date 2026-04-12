import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

typedef AdminNavItem = ({String label, IconData icon});

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final List<AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  static const double expandedW = 276;
  static const double collapsedW = 76;

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? collapsedW : expandedW;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: w,
      decoration: BoxDecoration(
        color: GirgoBrand.white,
        border: const Border(
          right: BorderSide(color: GirgoBrand.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: GirgoBrand.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 12 : 16, 20, collapsed ? 12 : 12, 12),
              child: Row(
                children: [
                  if (!collapsed) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [GirgoBrand.green, GirgoBrand.greenMid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: GirgoBrand.green.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                  ] else
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GirgoBrand.greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dashboard_rounded, color: GirgoBrand.green, size: 22),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                    onPressed: onToggleCollapse,
                    icon: Icon(
                      collapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.menu_open_rounded,
                      color: GirgoBrand.blackMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: GirgoBrand.borderLight),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SidebarTile(
                      icon: item.icon,
                      label: item.label,
                      selected: selected,
                      collapsed: collapsed,
                      onTap: () => onSelect(index),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                collapsed ? '' : 'v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: GirgoBrand.black.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? GirgoBrand.greenSoft
        : _hover
            ? GirgoBrand.offWhite
            : Colors.transparent;
    final fg = widget.selected ? GirgoBrand.green : GirgoBrand.blackMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: GirgoBrand.green.withValues(alpha: 0.06),
          splashColor: GirgoBrand.green.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.selected
                    ? GirgoBrand.green.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: widget.collapsed
                ? Center(
                    child: Icon(widget.icon, color: fg, size: 22),
                  )
                : Row(
                    children: [
                      Icon(widget.icon, color: fg, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 13.5,
                            color: fg,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: GirgoBrand.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
