import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _taglineFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _dotsFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    // Sequence: logo first, then text
    _logoController.forward().then((_) {
      _textController.forward();
    });

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2340),
              Color(0xFF1E2843),
              Color(0xFF141C36),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles background
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF2B300).withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF2B300).withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF2B300).withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Logo circle
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF2B300).withValues(alpha: 0.4),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    'assets/images/logo_bengkel.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── App Name ──────────────────────────────────────
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            // "Bengkelku" with highlight on "ku"
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Bengkel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ku',
                                    style: TextStyle(
                                      color: Color(0xFFF2B300),
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Tagline
                            FadeTransition(
                              opacity: _taglineFade,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 1,
                                    color: const Color(0xFFF2B300).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Solusi Otomotif di Genggaman',
                                    style: TextStyle(
                                      color: Color(0xFF8C96A8),
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 24,
                                    height: 1,
                                    color: const Color(0xFFF2B300).withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // ── Loading dots ──────────────────────────────────
                    FadeTransition(
                      opacity: _dotsFade,
                      child: _LoadingDots(),
                    ),
                  ],
                ),
              ),

              // Version tag bottom
              FadeTransition(
                opacity: _taglineFade,
                child: const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4A5568),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Loading Dots ─────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    _startSequence();
  }

  void _startSequence() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 150));
      if (mounted) {
        _controllers[i].repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FadeTransition(
            opacity: _animations[i],
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF2B300),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
