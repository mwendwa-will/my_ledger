import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_onboarded', true);
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            }
          },
          child: const Text('Start (Skip Onboarding)'),
        ),
      ),
    );
  }
}
