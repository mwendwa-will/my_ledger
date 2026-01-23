import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../utils/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      if (canAuthenticateWithBiometrics) {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (authenticated) {
          await prefs.setBool('biometric_enabled', true);
          setState(() => _isBiometricEnabled = true);
        }
      } else {
          if (mounted) {
            ScaffoldMessenger.of(context as BuildContext).showSnackBar(const SnackBar(content: Text('Biometrics not available on this device')));
          }
      }
    } else {
      await prefs.setBool('biometric_enabled', false);
      setState(() => _isBiometricEnabled = false);
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
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          
          _buildSectionHeader('General'),
          ListTile(
            title: const Text('Currency Symbol'),
            subtitle: Text(currency),
            leading: const Icon(Icons.attach_money),
            onTap: () {
              _showCurrencyDialog(ref);
            },
          ),
          SwitchListTile(
            title: const Text('Biometric Security'),
            subtitle: const Text('Require fingerprint/face to open app'),
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
            secondary: const Icon(Icons.fingerprint),
          ),
          
          _buildSectionHeader('Data Management'),
          ListTile(
            title: const Text('Backup Data'),
            subtitle: const Text('Export database file'),
            leading: const Icon(Icons.upload),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(this.context);
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
              final messenger = ScaffoldMessenger.of(this.context);
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
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            onTap: () {
              _showDeleteAllDialog();
            },
          ),
          
          const SizedBox(height: 32),
          const Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
        title,
        style: TextStyle(
          color: Theme.of(this.context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  void _showCurrencyDialog(WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(currencySymbolProvider));
    showDialog(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Currency Symbol'),
        content: TextField(
          controller: controller,
          maxLength: 3,
          decoration: const InputDecoration(labelText: 'Symbol'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(currencySymbolProvider.notifier).setCurrency(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Nuclear option
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              final dbPath = await getDatabasesPath();
              final path = join(dbPath, AppConstants.dbName);
              await deleteDatabase(path);
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text('All data deleted. Restarting...')));
              // In a real app we might trigger a full state reset, here we just ask user to restart or reset navigation
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
