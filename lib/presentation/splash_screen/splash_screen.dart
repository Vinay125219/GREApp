import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production auth state check
  late AnimationController _logoController;
  late AnimationController _gradientController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _gradientShift;

  @override
  void initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle is a no-op on Flutter Web
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
    }

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _gradientShift = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    _gradientController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _gradientController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientShift,
        builder: (context, child) {
          final t = _gradientShift.value;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF0F172A),
                    const Color(0xFF1E3A8A),
                    t,
                  )!,
                  Color.lerp(
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1D4ED8),
                    t,
                  )!,
                  Color.lerp(
                    const Color(0xFF1D4ED8),
                    const Color(0xFF0F766E),
                    t * 0.4,
                  )!,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles - extend beyond safe area intentionally
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              // Main content
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 360 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: isTablet ? 120 : 100,
                          height: isTablet ? 120 : 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 52,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 32 : 28),
                      // App name
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _textOpacity,
                            child: SlideTransition(
                              position: _textSlide,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'GREApp',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: isTablet ? 36 : 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Gateway to Exam Success',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GRE · GMAT · SAT · ACT · CAT',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: isTablet ? 13 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom loading indicator
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(opacity: _textOpacity.value, child: child);
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Powered by GREApp Platform',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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
