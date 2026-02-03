import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Formats a double value into a currency string.
  /// 
  /// [amount]: The number to format (e.g., 1000.50)
  /// [currencyCode]: The ISO 4217 code (e.g., 'USD', 'EUR', 'JPY')
  /// [locale]: Optional locale to force formatting rules (e.g., 'en_US')
  static String format(double amount, {String currencyCode = 'USD', String? locale, int? decimalDigits}) {
    // NumberFormat.simpleCurrency automatically determines the symbol 
    // and the decimal/thousand separators based on the code/locale.
    // If locale is null, it defaults to the system locale or 'en_US' if not set.
    // However, if we pass the currency name, it tries to use that currency's conventions.
    
    try {
      final format = NumberFormat.simpleCurrency(
        name: currencyCode, 
        locale: locale, 
        decimalDigits: decimalDigits,
      );
      return format.format(amount);
    } catch (e) {
      // Fallback if something goes wrong
      return '$currencyCode ${amount.toStringAsFixed(decimalDigits ?? 2)}';
    }
  }

  /// Gets the symbol for a specific code (e.g., USD -> $)
  static String getSymbol(String currencyCode) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    } catch (e) {
      return currencyCode;
    }
  }
}
