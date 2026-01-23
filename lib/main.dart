import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final isOnboarded = prefs.getBool('is_onboarded') ?? false;

  runApp(ProviderScope(
    child: MyLedgerApp(isOnboarded: isOnboarded),
  ));
}

class MyLedgerApp extends ConsumerWidget {

  const MyLedgerApp({super.key, required this.isOnboarded});
  final bool isOnboarded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isOnboarded ? const MainScreen() : const OnboardingScreen(),
    );
  }
}