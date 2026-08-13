import 'package:flutter/material.dart';

import '../core/constants/app_theme.dart';

/// Premium gradient scaffold background.
///
/// Wraps any screen content with the app's signature dark gradient
/// and optional overlay for glassmorphism effects.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool addOverlay;

  const GradientBackground({
    super.key,
    required this.child,
    this.addOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: addOverlay
          ? Stack(
              children: [
                // Subtle radial accent
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00BFA6).withAlpha(25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3D8BFF).withAlpha(20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}
