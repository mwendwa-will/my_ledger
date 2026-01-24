import 'package:flutter/material.dart';

/// A reusable bottom action bar for bottom sheets that responds to keyboard
/// with smooth animations and proper safe area handling
class BottomSheetActionBar extends StatelessWidget {
  const BottomSheetActionBar({
    super.key,
    required this.child,
    this.showDivider = true,
    this.backgroundColor,
    this.elevation = 8.0,
  });

  final Widget child;
  final bool showDivider;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + keyboardHeight,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: showDivider
            ? Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              )
            : null,
        boxShadow: showDivider
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
