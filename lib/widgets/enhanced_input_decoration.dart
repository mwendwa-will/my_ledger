import 'package:flutter/material.dart';

/// Enhanced input decoration theme for consistent text field styling
class EnhancedInputDecoration {
  /// Creates an enhanced InputDecoration with consistent styling
  static InputDecoration create({
    required BuildContext context,
    String? labelText,
    String? hintText,
    String? helperText,
    String? prefixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool isDense = false,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isDense ? 12 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.error,
        ),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }

  /// Creates an enhanced decoration specifically for the amount field
  static InputDecoration createForAmount({
    required BuildContext context,
    required String currencySymbol,
    String? errorText,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: 'Amount',
      hintText: 'Enter amount',
      helperText: 'Use +, -, *, / for calculations',
      prefixText: '$currencySymbol ',
      errorText: errorText,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      prefixStyle: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          width: 1.5,
          color: theme.colorScheme.error,
        ),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }

  /// Creates an enhanced decoration for dropdown fields
  static InputDecoration createForDropdown({
    required BuildContext context,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return create(
      context: context,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isDense: true,
    );
  }
}
