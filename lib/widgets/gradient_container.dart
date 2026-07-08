// lib/widgets/gradient_container.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';  // ✅ ADD THIS IMPORT

class GradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;

  const GradientContainer({
    super.key,
    required this.child,
    this.colors,
    this.height = double.infinity,
    this.width = double.infinity,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [
      AppTheme.primaryColor,
      AppTheme.primaryColor.withOpacity(0.7),
    ];

    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [
      AppTheme.primaryColor,
      AppTheme.primaryColor.withOpacity(0.6),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}