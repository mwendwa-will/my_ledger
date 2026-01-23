import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, {String symbol = r'$'}) {
    final format = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  static String formatShortDate(DateTime date) {
    return DateFormat.MMMd().format(date);
  }
}
