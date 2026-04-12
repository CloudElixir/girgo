import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme.dart';
import '../../utils/dashboard_formatters.dart';
import 'shimmer_placeholder.dart';

/// Premium KPI card: gradient frame, depth, icon, shimmer, hover motion.
class DashboardStatCard extends StatefulWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    this.value,
    this.isLoading = true,
    this.trendLabel,
    this.trendUp,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final int? value;
  final bool isLoading;
  final String? trendLabel;
  final bool? trendUp;

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  bool _hover = false;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final scale = _hover ? 1.012 : 1.0;
    final shadowA = _hover ? 0.12 : 0.07;
    final shadowB = _hover ? 0.18 : 0.10;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius + 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accent.withValues(alpha: 0.55),
                widget.accent.withValues(alpha: 0.12),
                GirgoBrand.borderLight.withValues(alpha: 0.4),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: GirgoBrand.black.withValues(alpha: shadowA),
                blurRadius: _hover ? 36 : 28,
                offset: Offset(0, _hover ? 14 : 10),
              ),
              BoxShadow(
                color: widget.accent.withValues(alpha: shadowB * 0.35),
                blurRadius: _hover ? 28 : 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.35),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GirgoBrand.white,
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                BoxShadow(
                  color: GirgoBrand.white.withValues(alpha: 0.9),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {},
                splashColor: widget.accent.withValues(alpha: 0.08),
                highlightColor: widget.accent.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GirgoBrand.blackMuted.withValues(alpha: 0.82),
                                    letterSpacing: 0.2,
                                    height: 1.25,
                                  ),
                                ),
                                if (widget.trendLabel != null && widget.trendUp != null) ...[
                                  const SizedBox(height: 8),
                                  _TrendChip(
                                    label: widget.trendLabel!,
                                    up: widget.trendUp!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.accent.withValues(alpha: 0.16),
                                  widget.accent.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: GirgoBrand.white.withValues(alpha: 0.95),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accent.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accent,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: widget.isLoading
                            ? Column(
                                key: const ValueKey('sk'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(width: 112, height: 34, borderRadius: 10),
                                  const SizedBox(height: 10),
                                  ShimmerBox(width: 72, height: 11, borderRadius: 6),
                                ],
                              )
                            : Text(
                                formatDashboardInteger(widget.value ?? 0),
                                key: ValueKey('v-${widget.value}'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: GirgoBrand.black,
                                  letterSpacing: -1.1,
                                  height: 1.05,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.label, required this.up});

  final String label;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final color = up ? const Color(0xFF14805E) : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
