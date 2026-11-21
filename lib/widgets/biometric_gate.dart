import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricGate extends StatefulWidget {
  const BiometricGate({
    super.key,
    required this.child,
    this.authenticate,
  });

  final Widget child;
  final Future<bool> Function()? authenticate;

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isUnlocked = false;
  bool _isChecking = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateIfRequired();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_isUnlocked) {
        setState(() {
          _isUnlocked = false;
          _isChecking = true;
          _errorMessage = null;
        });
      }
    } else if (state == AppLifecycleState.resumed && !_isUnlocked) {
      _authenticateIfRequired();
    }
  }

  Future<void> _authenticateIfRequired() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (!(prefs.getBool('biometric_enabled') ?? false)) {
        if (mounted) {
          setState(() {
            _isUnlocked = true;
            _isChecking = false;
            _errorMessage = null;
          });
        }
        return;
      }

      final authenticated = widget.authenticate != null
          ? await widget.authenticate!()
          : await _auth.authenticate(
              localizedReason: 'Authenticate to open MyLedger',
              persistAcrossBackgrounding: true,
              biometricOnly: false,
            );
      if (mounted) {
        setState(() {
          _isUnlocked = authenticated;
          _isChecking = false;
          _errorMessage =
              authenticated ? null : 'Authentication was not completed.';
        });
      }
    } on LocalAuthException catch (error) {
      if (mounted) {
        setState(() {
          _isUnlocked = false;
          _isChecking = false;
          _errorMessage =
              'Authentication failed: ${error.description ?? error.code.name}';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _isUnlocked = false;
          _isChecking = false;
          _errorMessage = 'Authentication failed: ${error.message}';
        });
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) return widget.child;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Unlock MyLedger to continue'),
              const SizedBox(height: 16),
              if (_isChecking)
                const CircularProgressIndicator()
              else
                FilledButton(
                  onPressed: _isAuthenticating ? null : _authenticateIfRequired,
                  child: const Text('Try again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
