import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import '../theme/app_shadows.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late final AnimationController _entryController;
  late final AnimationController _rotationController;
  late final AnimationController _starController;
  late final AnimationController _buttonPulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entry Fade
    _entryController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    // 2. Slow Rotation (Magic Circle) - 20s
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // 3. Twinkling Stars
    _starController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _starAnimation = CurvedAnimation(parent: _starController, curve: Curves.easeInOut);

    // 4. Button Pulse
    _buttonPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rotationController.dispose();
    _starController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Assuming magic circle takes up a good portion of the center
    // We position text above it.

    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep Space Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000), // Black
                  Color(0xFF0A0A2A), // Dark Navy
                  Color(0xFF1A1A3A), // Deep Purple/Blue hint
                ],
              ),
            ),
          ),

          // 2. Twinkling Stars
          AnimatedBuilder(
            animation: _starAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _StarPainter(_starAnimation.value),
              );
            },
          ),

          // 3. Rotating Magic Circle (Center)
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Opacity(
                    opacity: 0.2, // Requirement: 0.2
                    child: CustomPaint(
                      size: const Size(600, 600),
                      painter: _MagicCirclePainter(),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Content Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title Area (Above Magic Circle Center)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                       Text(
                        "精霊召喚の世界へようこそ",
                        style: TextStyle(
                          fontFamily: 'Roboto', 
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Welcome to Magical Vibe",
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 28, // Slightly smaller than ElementSelection to fit
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: AppShadows.whiteSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80), // Space between title and center button

                // Start Button (Center of Magic Circle)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _StartButton(
                    onTap: _onStartPressed,
                    pulseController: _buttonPulseController,
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

// ------ UI Components ------

class _StartButton extends StatefulWidget {
  final VoidCallback onTap;
  final AnimationController pulseController;

  const _StartButton({
    required this.onTap,
    required this.pulseController,
  });

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, child) {
            final scale = 1.0 + (widget.pulseController.value * 0.05); // 1.0 to 1.05
            return Transform.scale(
              scale: _isHovered ? 1.1 : scale, // Hover overrides pulse scale
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // When hovered, opacity increases (less transparent = more visible)
              // Requirement: "Selected (Hover) -> Half-transparent removed"
              color: _isHovered 
                  ? Colors.white.withOpacity(0.15) 
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: _isHovered ? Colors.white : Colors.white54,
                width: _isHovered ? 2.0 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      SafeBoxShadow.build(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ]
                  : [
                      SafeBoxShadow.build(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 40,
                  color: _isHovered ? Colors.white : Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  "開始\nSTART",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isHovered ? Colors.white : Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    height: 1.2,
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

// ------ Painters (Copied from ElementSelectionScreen for consistency) ------

class _StarPainter extends CustomPainter {
  final double animationValue;

  _StarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(12345); 

    for (int i = 0; i < 50; i++) {
        double x = random.nextDouble() * size.width;
        double y = random.nextDouble() * size.height;
        double baseSize = random.nextDouble() * 2 + 1;
        
        double twinkle = math.sin((animationValue * 2 * math.pi) + random.nextDouble() * 10);
        double opacity = (twinkle + 1) / 2 * 0.7 + 0.3;

        paint.color = Colors.white.withOpacity(opacity);
        canvas.drawCircle(Offset(x, y), baseSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => true;
}

class _MagicCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Outer Circles
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.95, paint);

    // 2. Hexagon
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 2 * math.pi / 6) - (math.pi / 2);
      double x = center.dx + radius * 0.95 * math.cos(angle);
      double y = center.dy + radius * 0.95 * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
    
    // 3. Inner Hexagon (Rotated)
     final path2 = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 2 * math.pi / 6); 
      double x = center.dx + radius * 0.95 * math.cos(angle);
      double y = center.dy + radius * 0.95 * math.sin(angle);
      if (i == 0) path2.moveTo(x, y);
      else path2.lineTo(x, y);
    }
    path2.close();
    canvas.drawPath(path2, paint);

    // 4. Inner Circle
    canvas.drawCircle(center, radius * 0.6, paint);
    
    // 5. Square (Diamond)
    final pathDiamond = Path();
    pathDiamond.moveTo(center.dx, center.dy - radius * 0.6);
    pathDiamond.lineTo(center.dx + radius * 0.6, center.dy);
    pathDiamond.lineTo(center.dx, center.dy + radius * 0.6);
    pathDiamond.lineTo(center.dx - radius * 0.6, center.dy);
    pathDiamond.close();
    canvas.drawPath(pathDiamond, paint);

    // 6. Runes / Detail Dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      double angle = i * (math.pi / 6);
      double x = center.dx + radius * 0.8 * math.cos(angle);
      double y = center.dy + radius * 0.8 * math.sin(angle);
      canvas.drawCircle(Offset(x,y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
