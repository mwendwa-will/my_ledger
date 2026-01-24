import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:my_ledger/models/account.dart';
import 'package:my_ledger/models/category.dart';
import 'package:my_ledger/models/enums.dart';
import 'package:my_ledger/providers/settings_provider.dart';
import 'package:my_ledger/services/database_service.dart';
import 'package:my_ledger/screens/onboarding/add_first_account_screen.dart';
import 'package:my_ledger/screens/onboarding/currency_selection_screen.dart';
import 'package:my_ledger/screens/onboarding/quick_categories_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0;
  static const int numPages = 7; // Welcome + 3 Value Props + 3 Setup Steps

  // State for setup screens
  String _selectedCurrencyCode = 'USD'; // Default value
  String _accountName = 'Checking Account';
  AccountType _accountType = AccountType.checking;
  double _startingBalance = 0.0;
  List<Map<String, dynamic>> _selectedCategories = [];
  bool _showSuccessOverlay = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  Future<void> _showSuccessAnimation() async {
    await SemanticsService.sendAnnouncement(WidgetsBinding.instance.platformDispatcher.views.first, 'Setup Complete!', TextDirection.ltr); // Announce completion
    setState(() {
      _showSuccessOverlay = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500)); // Show for 1.5 seconds
    setState(() {
      _showSuccessOverlay = false;
    });
  }

  Future<void> _completeOnboarding() async {
    await HapticFeedback.lightImpact(); // Haptic feedback on completion

    // Save currency
    await ref.read(currencyCodeProvider.notifier).setCurrencyCode(_selectedCurrencyCode);

    // Save account
    final newAccount = Account(
      name: _accountName,
      type: _accountType,
      initialBalance: _startingBalance,
      currentBalance: _startingBalance,
      color: Colors.blue.toARGB32(), // Default color for now
      iconCodePoint: _accountType == AccountType.checking ? Icons.account_balance.codePoint : Icons.savings.codePoint, // Default icon for now
    );
    await DatabaseService.instance.createAccount(newAccount);

    // Save categories
    for (final catData in _selectedCategories) {
      final category = Category(
        name: catData['name'],
        type: catData['type'],
        color: (catData['color'] as Color).toARGB32(),
        iconCodePoint: (catData['icon'] as IconData).codePoint,
      );
      await DatabaseService.instance.createCategory(category);
    }


    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);

    if (mounted) {
      await _showSuccessAnimation(); // Show animation before navigating
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    namesRoute: true,
                    child: PageView(
                    controller: _pageController,
                    children: [
                      const OnboardingPage(
                        image: 'assets/images/welcome.png',
                        title: 'Welcome to MyLedger',
                        description:
                            'Your finances, completely private and offline.',
                      ),
                      const OnboardingPage(
                        image: 'assets/images/track.png',
                        title: 'Track Every Dollar',
                        description:
                            'Record income and expenses with a tap. Know exactly where your money goes.',
                      ),
                      const OnboardingPage(
                        image: 'assets/images/budget.png',
                        title: 'Stay on Budget',
                        description:
                            'Set spending limits and get alerts before you overspend.',
                      ),
                      const OnboardingPage(
                        image: 'assets/images/privacy.png',
                        title: 'Your Data Stays Yours',
                        description:
                            'Everything stays on your device. No cloud sync, no tracking, completely private.',
                      ),
                      CurrencySelectionScreen(
                        onCurrencySelected: (code) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _selectedCurrencyCode = code;
                            });
                          });
                        },
                        initialCurrencyCode: _selectedCurrencyCode,
                      ),
                      AddFirstAccountScreen(
                        onAccountNameChanged: (name) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _accountName = name;
                            });
                          });
                        },
                        onAccountTypeChanged: (type) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _accountType = type;
                            });
                          });
                        },
                        onStartingBalanceChanged: (balance) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _startingBalance = balance;
                            });
                          });
                        },
                        initialAccountName: _accountName,
                        initialAccountType: _accountType,
                        initialStartingBalance: _startingBalance,
                      ),
                      QuickCategoriesScreen(
                        onCategoriesSelected: (categories) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _selectedCategories = categories;
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),),
                Semantics(
                  label: 'Page ${(_currentPage + 1).round()} of $numPages',
                  value: '${(_currentPage + 1).round()}',
                  maxValueLength: numPages,
                  child: DotsIndicator(
                    dotsCount: numPages,
                    position: _currentPage,
                    decorator: DotsDecorator(
                      size: const Size.square(9.0),
                      activeSize: const Size(18.0, 9.0),
                      activeShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact(); // Haptic feedback on skip
                          _completeOnboarding();
                        },
                        child: const Text('Skip'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact(); // Haptic feedback on next
                          if (_currentPage < numPages - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        child: Text(_currentPage < numPages - 1 ? 'Next' : 'Get Started'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (_showSuccessOverlay)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.surface.withAlpha((0.9 * 255).round()),
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showSuccessOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Setup Complete!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

}

Widget _buildOnboardingGraphic(BuildContext context, String image) {
  final color = Theme.of(context).colorScheme.primary;
  IconData icon;
  final key = image.toLowerCase();
  if (key.contains('welcome')) {
    icon = FontAwesomeIcons.wallet;
  } else if (key.contains('track')) {
    icon = FontAwesomeIcons.chartLine;
  } else if (key.contains('budget')) {
    icon = FontAwesomeIcons.piggyBank;
  } else if (key.contains('privacy')) {
    icon = FontAwesomeIcons.userShield;
  } else {
    icon = FontAwesomeIcons.image;
  }

  return SizedBox(
    height: 250,
    child: Center(
      child: FaIcon(
        icon,
        size: 120,
        color: color,
      ),
    ),
  );
}

class OnboardingPage extends StatelessWidget {

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });
  final String image;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $description', // Combine title and description for screen readers
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use FontAwesome icons as temporary placeholders instead of image files
            _buildOnboardingGraphic(context, image),
            const SizedBox(height: 40),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}