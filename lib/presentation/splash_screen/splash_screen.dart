import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  String _statusLabel = 'Chargement des offres...';

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        if (!mounted) return;
        if (_progressController.value > 0.88 &&
            _statusLabel != 'Bienvenue sur Wetio !') {
          setState(() {
            _statusLabel = 'Bienvenue sur Wetio !';
          });
        } else if (_progressController.value > 0.50 &&
            _progressController.value <= 0.88 &&
            _statusLabel != 'Préparation de la boutique...') {
          setState(() {
            _statusLabel = 'Préparation de la boutique...';
          });
        }
      });

    _progressController.forward();

    Timer(const Duration(milliseconds: 1650), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.homeFeed);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Illustration Stage (220x220, identical to web/index.html)
                SizedBox(
                  width: 220,
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_floatController.value);
                      final heroOffsetY = -9.0 * t;
                      final badge1OffsetY = -7.0 * t;
                      final badge2OffsetY = 6.0 * t;
                      final shadowScale = 1.0 - (0.18 * t);
                      final shadowOpacity = 0.75 - (0.30 * t);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main organic blob
                          Transform.rotate(
                            angle: (t * 10.0) * math.pi / 180.0,
                            child: Transform.scale(
                              scale: 1.0 + (0.04 * t),
                              child: Container(
                                width: 185,
                                height: 185,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(82),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4CAF50).withValues(alpha: 0.14),
                                      const Color(0xFFEE7838).withValues(alpha: 0.12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Secondary organic blob
                          Transform.rotate(
                            angle: -((1.0 - t) * 10.0) * math.pi / 180.0,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(70),
                                color: const Color(0xFF4D7C55).withValues(alpha: 0.09),
                              ),
                            ),
                          ),

                          // Shadow ellipse below illustration
                          Positioned(
                            bottom: 4,
                            child: Transform.scale(
                              scaleX: shadowScale,
                              scaleY: 1.0,
                              child: Opacity(
                                opacity: shadowOpacity,
                                child: Container(
                                  width: 110,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4D7C55).withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Central Official WETIO Logo Card
                          Transform.translate(
                            offset: Offset(0, heroOffsetY),
                            child: Container(
                              width: 128,
                              height: 128,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4D7C55).withValues(alpha: 0.14),
                                    blurRadius: 40,
                                    offset: const Offset(0, 18),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFEE7838).withValues(alpha: 0.10),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/Wetio-1762471032439.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Top-right Exchange (Wetio) Badge
                          Positioned(
                            top: 16,
                            right: 12,
                            child: Transform.translate(
                              offset: Offset(0, badge1OffsetY),
                              child: Transform.rotate(
                                angle: (t * 6.0) * math.pi / 180.0,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF7043),
                                        Color(0xFFF4511E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom-left Shopping Bag Badge
                          Positioned(
                            bottom: 20,
                            left: 10,
                            child: Transform.translate(
                              offset: Offset(0, badge2OffsetY),
                              child: Transform.rotate(
                                angle: -(t * 6.0) * math.pi / 180.0,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF2E7D32),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom-right Fast Delivery Badge
                          Positioned(
                            bottom: 16,
                            right: 18,
                            child: Transform.translate(
                              offset: Offset(0, -badge1OffsetY * 0.8),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: Color(0xFF388E3C),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // Brand Title "Wetio."
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Wet',
                        style: TextStyle(color: Color(0xFF4D7C55)),
                      ),
                      TextSpan(
                        text: 'io',
                        style: TextStyle(color: Color(0xFFEE7838)),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: Color(0xFF263228)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Échangez, achetez et vendez en toute sécurité',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E7770),
                    letterSpacing: 0.1,
                  ),
                ),

                const SizedBox(height: 34),

                // Smooth Animated Progress Bar
                SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: const Color(0xFF4D7C55).withValues(alpha: 0.12),
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              final p = Curves.easeOutCubic
                                  .transform(_progressController.value)
                                  .clamp(0.18, 1.0);
                              return FractionallySizedBox(
                                widthFactor: p,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFFFF7043),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF848D86),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

