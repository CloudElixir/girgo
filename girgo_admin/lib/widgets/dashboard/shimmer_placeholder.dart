import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

/// Lightweight shimmer tuned to Girgo greens (no extra packages).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _c.value;
            return LinearGradient(
              begin: Alignment(-1.2 + t * 2.4, 0),
              end: Alignment(0.2 + t * 2.4, 0),
              colors: [
                GirgoBrand.greenSoft.withValues(alpha: 0.45),
                GirgoBrand.white,
                GirgoBrand.greenSoft.withValues(alpha: 0.45),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: GirgoBrand.borderLight.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
