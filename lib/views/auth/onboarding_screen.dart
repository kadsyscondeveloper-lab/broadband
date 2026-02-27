import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Entry point ────────────────────────────────────────────────────────────────
// Call OnboardingScreen and pass [onComplete] callback.
// On "Skip" or "Get Started" → onComplete() is invoked.
//
// In main.dart / router, show OnboardingScreen on first launch, then
// navigate to LoginScreen afterwards.

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _totalPages = 3;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() => widget.onComplete();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Page View ───────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: const [
                    _OnboardingPage(
                      illustrationAsset:
                      'assets/images/onboarding_1.png', // replace with your asset
                      title: 'Welcome to\nSpeedonet Broadband',
                      description:
                      'Stay connected with lightning-fast broadband, built for your needs. Experience seamless speed, effortless control. Your internet, your way — let\'s get started!',
                    ),
                    _OnboardingPage(
                      illustrationAsset:
                      'assets/images/onboarding_2.png', // replace with your asset
                      title: 'Blazing-fast\ninternet at your fingertips',
                      description:
                      'Enjoy ultra-speed connectivity with no interruptions. Stream, game, and browse without limits. Experience the power of seamless broadband. Stay ahead with lightning-fast speeds anytime, anywhere!',
                    ),
                    _OnboardingPage(
                      illustrationAsset:
                      'assets/images/onboarding_3.png', // replace with your asset
                      title: 'Stay in Control with\nReal-Time Usage Tracking',
                      description:
                      'Take control of your internet usage with real-time tracking. Monitor data consumption, check your plan details, and stay updated effortlessly. Manage your broadband with ease and confidence!',
                    ),
                  ],
                ),
              ),

              // ── Dots ────────────────────────────────────────────────────
              _DotsIndicator(
                count: _totalPages,
                activeIndex: _currentPage,
              ),
              const SizedBox(height: 28),

              // ── Buttons ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _currentPage < _totalPages - 1
                    ? Row(
                  children: [
                    // Skip button
                    Expanded(
                      child: _OutlineButton(
                        label: 'Skip',
                        onTap: _skip,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Next button
                    Expanded(
                      child: _PrimaryButton(
                        label: 'Next',
                        onTap: _next,
                      ),
                    ),
                  ],
                )
                    : _PrimaryButton(
                  label: 'Get Started',
                  onTap: _next,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single onboarding page ────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final String illustrationAsset;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.illustrationAsset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Illustration takes ~50% of the remaining space
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Image.asset(
                illustrationAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _PlaceholderIllustration(index: title.startsWith('W')
                        ? 0
                        : title.startsWith('B')
                        ? 1
                        : 2),
              ),
            ),
          ),

          // Text section
          Expanded(
            flex: 4,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF888888),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dots indicator ────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotsIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE53935) // red primary
                : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: const Color(0xFFE53935).withOpacity(0.35),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ── Placeholder illustration (shown when assets aren't added yet) ─────────────
// Remove this once you add your actual PNG assets.

class _PlaceholderIllustration extends StatelessWidget {
  final int index;
  const _PlaceholderIllustration({required this.index});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    const lightRed = Color(0xFFFFCDD2);

    return CustomPaint(
      painter: _IllustrationPainter(index: index),
      child: const SizedBox.expand(),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final int index;
  _IllustrationPainter({required this.index});

  @override
  void paint(Canvas canvas, Size size) {
    const red = Color(0xFFE8534A);
    const lightRed = Color(0xFFFFCDD2);

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw a simple wifi arc illustration as fallback
    final center = Offset(size.width / 2, size.height * 0.55);

    // Outer arc
    paint.color = red.withOpacity(0.85);
    canvas.drawArc(
      Rect.fromCenter(
          center: center, width: size.width * 0.75, height: size.width * 0.75),
      3.14,
      3.14,
      false,
      paint..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.065
        ..strokeCap = StrokeCap.round,
    );

    // Mid arc
    paint.color = red.withOpacity(0.75);
    canvas.drawArc(
      Rect.fromCenter(
          center: center, width: size.width * 0.5, height: size.width * 0.5),
      3.14,
      3.14,
      false,
      paint..strokeWidth = size.width * 0.065,
    );

    // Inner arc
    paint.color = red.withOpacity(0.65);
    canvas.drawArc(
      Rect.fromCenter(
          center: center, width: size.width * 0.26, height: size.width * 0.26),
      3.14,
      3.14,
      false,
      paint..strokeWidth = size.width * 0.065,
    );

    // Dot
    paint
      ..style = PaintingStyle.fill
      ..color = red;
    canvas.drawCircle(center, size.width * 0.042, paint);

    // Clouds
    paint.color = lightRed;
    _drawCloud(canvas, paint, Offset(size.width * 0.15, size.height * 0.18),
        size.width * 0.09);
    _drawCloud(canvas, paint, Offset(size.width * 0.82, size.height * 0.22),
        size.width * 0.07);
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double r) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center.translate(r * 1.2, 0), r * 0.8, paint);
    canvas.drawCircle(center.translate(-r * 1.0, r * 0.1), r * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}