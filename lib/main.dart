import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ntt_atom_flutter/ntt_atom_flutter.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'core/storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService().init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SpeedonetApp());
}

class SpeedonetApp extends StatelessWidget {
  const SpeedonetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                  'Speedonet',
      debugShowCheckedModeBanner: false,
      theme:                  AppTheme.theme,
      navigatorObservers:     [AtomSDK.navigatorObserver],
      home:                   const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _storage = StorageService();
  final _auth    = AuthService();

  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (_storage.hasToken) {
      final user = await _auth.getMe();
      if (mounted) setState(() { _isLoggedIn = user != null; _isChecking = false; });
    } else {
      if (mounted) setState(() { _isLoggedIn = false; _isChecking = false; });
    }
  }

  void _onLoginSuccess() => setState(() => _isLoggedIn = true);

  /// Called by AppShell when the user taps Logout.
  /// AuthService.logout() has already cleared storage by this point.
  void _onLogout() => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi, color: Colors.white, size: 64),
              SizedBox(height: 24),
              Text('Speedonet',
                  style: TextStyle(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: 1)),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ],
          ),
        ),
      );
    }
    return _isLoggedIn
        ? AppShell(onLogout: _onLogout)
        : LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}