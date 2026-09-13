import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glassmorphic surface with blur, translucent gradient, and subtle border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.gradient,
    this.color,
    this.border,
    this.shadows,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? (gradient == null ? const Color(0x0FFFFFFF) : null),
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x14FFFFFF), // ~8% white
                Color(0x06FFFFFF), // ~2.5% white
              ],
            ),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: const Color(0x1AFFFFFF), // ~10% white border
              width: 1.0,
            ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    Widget wrapped = ClipRRect(
      borderRadius: radius,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            )
          : content,
    );

    if (margin != null) {
      wrapped = Padding(padding: margin!, child: wrapped);
    }

    return wrapped;
  }
}
