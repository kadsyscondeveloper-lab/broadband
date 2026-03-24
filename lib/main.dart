import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ntt_atom_flutter/ntt_atom_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'core/storage_service.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/auth/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService().init();           // ← initialize FIRST
  await NotificationPushService().init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SpeedonetApp());
}

class SpeedonetApp extends StatefulWidget {
  const SpeedonetApp({super.key});

  @override
  State<SpeedonetApp> createState() => _SpeedonetAppState();
}

class _SpeedonetAppState extends State<SpeedonetApp> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInitial();

    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (mounted && connected != _hasInternet) {
        setState(() => _hasInternet = connected);
      }
    });
  }

  Future<void> _checkInitial() async {
    final results   = await Connectivity().checkConnectivity();
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (mounted) setState(() => _hasInternet = connected);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'Speedonet',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.theme,
      navigatorObservers:         [AtomSDK.navigatorObserver],

      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (!_hasInternet)
              Positioned.fill(
                child: _NoInternetOverlay(
                  onRetry: () async {
                    final results   = await Connectivity().checkConnectivity();
                    final connected = results.any((r) => r != ConnectivityResult.none);
                    if (mounted) setState(() => _hasInternet = connected);
                    if (!connected && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:         Text('Still no connection. Please check your network.'),
                          backgroundColor: Color(0xFFE31E24),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        );
      },

      home: const _AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO INTERNET OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class _NoInternetOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoInternetOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/no_internet.png',
                  width:  200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your Wi-Fi or mobile\ndata and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:    Color(0xFF8A8A8E),
                    height:   1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH GATE
// ─────────────────────────────────────────────────────────────────────────────

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _storage = StorageService();
  final _auth    = AuthService();

  bool _isChecking     = true;
  bool _isLoggedIn     = false;
  bool _showOnboarding = false;

  static const _kOnboardingDone = 'onboarding_done';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs          = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_kOnboardingDone) ?? false;

    if (_storage.hasToken) {
      final user = await _auth.getMe();
      if (mounted) {
        setState(() {
          _isLoggedIn     = user != null;
          _showOnboarding = !onboardingDone;
          _isChecking     = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn     = false;
          _showOnboarding = !onboardingDone;
          _isChecking     = false;
        });
      }
    }
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  void _onLoginSuccess() => setState(() => _isLoggedIn = true);
  void _onLogout()       => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
    // ── Splash — GIF fullscreen ───────────────────────────────────────────
    if (_isChecking) {
      return Scaffold(
        backgroundColor: const Color(0xFFE31E24),
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/loading_screen.gif',
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // ── Onboarding (first launch only) ───────────────────────────────────
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    // ── Main app ─────────────────────────────────────────────────────────
    return _isLoggedIn
        ? AppShell(onLogout: _onLogout)
        : LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}