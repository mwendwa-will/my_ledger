import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors (Professional Financial Blue/Green)
  static const Color primary = Color(0xFF006C50);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF8DF8CC);
  static const Color onPrimaryContainer = Color(0xFF002116);

  static const Color secondary = Color(0xFF4C6359);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCEE9DB);
  static const Color onSecondaryContainer = Color(0xFF082017);

  static const Color tertiary = Color(0xFF3F6375);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFC2E8FD);
  static const Color onTertiaryContainer = Color(0xFF001F2A);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color background = Color(0xFFFBFDFA);
  static const Color onBackground = Color(0xFF191C1B);
  static const Color surface = Color(0xFFFBFDFA);
  static const Color onSurface = Color(0xFF191C1B);
  
  // Custom Semantic Colors
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFC62828);
  static const Color warning = Color(0xFFED6C02);
  static const Color transfer = Color(0xFF0288D1);
}

class AppConstants {
  static const String appName = 'MyLedger';
  static const String dbName = 'my_ledger.db';
  
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double cardRadius = 12;
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 16;

  static const List<String> defaultAccountTypes = [
    'Checking',
    'Savings',
    'Credit Card',
    'Cash',
    'Investment',
  ];

  // Using code points for standard Material Icons to store in DB if needed, 
  // or just mapping strings to Icons in UI.
  static const Map<String, int> defaultCategoryIcons = {
    'Groceries': 0xe532, // local_grocery_store
    'Rent': 0xe318, // home
    'Utilities': 0xe337, // lightbulb
    'Transportation': 0xe531, // directions_car
    'Dining': 0xe56c, // restaurant
    'Entertainment': 0xe406, // movie
    'Healthcare': 0xe35b, // local_hospital
    'Shopping': 0xe8cc, // shopping_bag
    'Salary': 0xe263, // attach_money
    'Freelance': 0xe879, // work
    'Investments': 0xe8e5, // trending_up
  };

  static const List<int> defaultCategoryColors = [
    0xFFEF5350, // Red
    0xFFEC407A, // Pink
    0xFFAB47BC, // Purple
    0xFF7E57C2, // Deep Purple
    0xFF5C6BC0, // Indigo
    0xFF42A5F5, // Blue
    0xFF29B6F6, // Light Blue
    0xFF26C6DA, // Cyan
    0xFF26A69A, // Teal
    0xFF66BB6A, // Green
    0xFF9CCC65, // Light Green
    0xFFD4E157, // Lime
    0xFFFFEE58, // Yellow
    0xFFFFCA28, // Amber
    0xFFFFA726, // Orange
    0xFFFF7043, // Deep Orange
    0xFF8D6E63, // Brown
    0xFFBDBDBD, // Grey
    0xFF78909C, // Blue Grey
    0xFF424242, // Black
  ];
}
