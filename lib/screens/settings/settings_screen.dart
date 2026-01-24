import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../onboarding/onboarding_screen.dart';

import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';

import 'categories/categories_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    if (value) {
      final resultMessage = await _enableBiometricFlow();
      if (!context.mounted) {
        return;
      }
      if (resultMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultMessage)));
      } else {
        setState(() => _isBiometricEnabled = true);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
      }
    }
  }

  Future<String?> _enableBiometricFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
        return 'Biometrics not available on this device';
      }

    final authenticated = await auth.authenticate(
  localizedReason: 'Authenticate to enable biometric lock',
  // Use the parameter name from the definition (stickyAuth is called persistAcrossBackgrounding here)
  persistAcrossBackgrounding: true, 
  biometricOnly: false,
);

      if (authenticated) {
        await prefs.setBool('biometric_enabled', true);
        return null;
      }

      return 'Authentication failed';
    } on PlatformException catch (e) {
      return 'Biometric authentication not available: ${e.message}';
    } catch (e) {
      return 'Biometric error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          
          _buildSectionHeader(context, 'General'),
          ListTile(
            title: const Text('Categories'),
            leading: const Icon(Icons.category),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Currency Symbol'),
            subtitle: Text(currency),
            leading: const Icon(Icons.attach_money),
            onTap: () {
              _showCurrencyDialog(context, ref);
            },
          ),
          SwitchListTile(
            title: const Text('Biometric Security'),
            subtitle: const Text('Require fingerprint/face to open app'),
            value: _isBiometricEnabled,
            onChanged: (val) => _toggleBiometric(context, val),
            secondary: const Icon(Icons.fingerprint),
          ),
          
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            title: const Text('Backup Data'),
            subtitle: const Text('Export database file'),
            leading: const Icon(Icons.upload),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await BackupService.exportDatabase();
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          ListTile(
            title: const Text('Restore Data'),
            subtitle: const Text('Import database file'),
            leading: const Icon(Icons.download),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final success = await BackupService.importDatabase();
                if (success) {
                   messenger.showSnackBar(const SnackBar(content: Text('Data restored. Please restart the app.')));
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all accounts and transactions'),
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            onTap: () {
              _showDeleteAllDialog(context);
            },
          ),
          
          const SizedBox(height: 32),
          Center(child: Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round())))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(currencyCodeProvider));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Currency Code'),
        content: Semantics(
          label: 'Currency Code input field', // Explicit semantic label
          child: TextField(
            controller: controller,
            maxLength: 3,
            decoration: const InputDecoration(labelText: 'Currency Code (e.g. USD)'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(currencyCodeProvider.notifier).setCurrencyCode(controller.text.toUpperCase());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will permanently delete all your data. This action cannot be undone.'),
            const SizedBox(height: 12),
            const Text('Type DELETE to confirm:'),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'DELETE'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim() != 'DELETE') {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Confirmation text did not match')));
                return;
              }
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await DatabaseService.instance.deleteAllData();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                messenger.showSnackBar(const SnackBar(content: Text('All data deleted. Restarting to onboarding...')));
                if (context.mounted) {
                  await Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error deleting data: $e')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
