import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_helper.dart';

// Currency Provider
final currencyCodeProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {

  CurrencyNotifier() : super('USD') { // Default to USD
    _loadCurrencyCode();
  }

  Future<void> _loadCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('currency_code') ?? 'USD';
  }

  Future<void> setCurrencyCode(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
  }

  String get currentCurrencySymbol => CurrencyHelper.getSymbol(state);
}

// Expose current currency symbol for convenience
final currencySymbolProvider = Provider<String>((ref) {
  final notifier = ref.watch(currencyCodeProvider.notifier);
  return notifier.currentCurrencySymbol;
});

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false) { // false = light, true = dark
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('is_dark_mode') ?? false;
  }

  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', state);
  }
}
