import 'package:flutter/material.dart';

class GradientProgressBar extends StatelessWidget {

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    required this.colors,
    this.backgroundColor = const Color(0xFFEEEEEE), // Default background color
  });
  final double value; // 0.0 to 1.0
  final double height;
  final BorderRadiusGeometry borderRadius;
  final List<Color> colors; // Colors for the gradient
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            LinearProgressIndicator(
              value: 1, // Always full width background
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
            ),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds);
              },
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0), // Actual progress
                backgroundColor: Colors.transparent, // Make background transparent to show ShaderMask
                valueColor: AlwaysStoppedAnimation<Color>(colors.last), // Fallback, color is handled by ShaderMask
              ),
            ),
          ],
        ),
      ),
    );
  }
}
