import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/futuristic_theme.dart';

// 1. Glass Container (Backdrop Filter)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final bool isStrong;
  final Color? color; // New parameter

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.4, // Default per CSS
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.isStrong = false,
    this.color, // Add to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Strong variant from glassmorphism.css
    final effectiveOpacity = isStrong ? 0.7 : 0.4;
    final effectiveBlur = isStrong ? 30.0 : 20.0;
    // Use provided color or default
    final bgColor = color ?? Color(0xFF0F0F19).withOpacity(effectiveOpacity); // rgba(15, 15, 25, 0.4)

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16), // --radius default
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.1),
                width: 1.0,
              ),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(isStrong ? 0.5 : 0.37),
                   blurRadius: 32,
                   offset: Offset(0, 8),
                 ),
              ]
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 2. Neon Button
class NeonButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? color;
  final bool isSecondary;
  final IconData? icon;

  const NeonButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.color,
    this.isSecondary = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? (isSecondary ? FuturisticTheme.secondaryViolet : FuturisticTheme.primaryCyan);
    final shadowColor = baseColor.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1), // Slight tint
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 0),
          )
        ],
        border: Border.all(color: baseColor.withOpacity(0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          splashColor: baseColor.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: baseColor, size: 20),
                  SizedBox(width: 8),
                ],
                Text(
                  text.toUpperCase(),
                  style: TextStyle(
                    color: baseColor, // Text glows with the color
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                    shadows: [
                      Shadow(color: baseColor.withOpacity(0.6), blurRadius: 10),
                    ],
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

// 3. Glowing Text header
class GlowingText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;

  const GlowingText(this.text, {Key? key, this.fontSize = 24, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? FuturisticTheme.primaryCyan;
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: effectiveColor,
            blurRadius: 20,
          ),
           Shadow(
            color: effectiveColor.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}
