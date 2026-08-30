import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft, blurred colour blobs painted behind every screen in the app.
/// Combined with the translucent glassmorphism cards/nav/sheets, this is
/// what the frosted-glass blur actually "frosts" — a flat solid colour
/// behind a blur filter looks identical to no blur at all, so the app
/// needs this gentle, colourful wash underneath.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBackground : AppColors.background;

    Widget blob({required Color color, required double size, required double blur}) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
    }

    final opacityBoost = isDark ? 1.6 : 1.0;

    return Container(
      color: base,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: blob(
              color: AppColors.primary.withOpacity(0.16 * opacityBoost),
              size: 260,
              blur: 70,
            ),
          ),
          Positioned(
            top: 140,
            right: -100,
            child: blob(
              color: AppColors.secondary.withOpacity(0.14 * opacityBoost),
              size: 300,
              blur: 80,
            ),
          ),
          Positioned(
            bottom: 60,
            left: -90,
            child: blob(
              color: AppColors.accent.withOpacity(0.12 * opacityBoost),
              size: 260,
              blur: 75,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: blob(
              color: AppColors.skyBlue.withOpacity(0.14 * opacityBoost),
              size: 280,
              blur: 80,
            ),
          ),
        ],
      ),
    );
  }
}
