import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import '../theme/app_shadows.dart';

class ElementSelectionScreen extends StatefulWidget {
  const ElementSelectionScreen({super.key});

  @override
  State<ElementSelectionScreen> createState() => _ElementSelectionScreenState();
}

class _ElementSelectionScreenState extends State<ElementSelectionScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late final AnimationController _entryController;
  late final AnimationController _rotationController;
  late final AnimationController _starController;
  late final AnimationController _pulseController; // For selected element

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _starAnimation;

  // Selected Element State
  int? _selectedIndex;

  // Element Data
  final List<Map<String, dynamic>> _elements = [
    {'name': 'Fire', 'color': const Color(0xFFFF4500), 'icon': Icons.local_fire_department},
    {'name': 'Water', 'color': const Color(0xFF2196F3), 'icon': Icons.water_drop},
    {'name': 'Thunder', 'color': const Color(0xFFFFD700), 'icon': Icons.flash_on},
    {'name': 'Ice', 'color': const Color(0xFF00FFFF), 'icon': Icons.ac_unit},
    {'name': 'Wind', 'color': const Color(0xFF00E676), 'icon': Icons.air},
    {'name': 'Light', 'color': const Color(0xFFFFF176), 'icon': Icons.wb_sunny},
    {'name': 'Dark', 'color': const Color(0xFF9C27B0), 'icon': Icons.nightlight_round},
  ];

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

    // 4. Pulse (Selected Element)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rotationController.dispose();
    _starController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onElementSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSummonPressed() {
    if (_selectedIndex == null) return;

    final selectedElement = _elements[_selectedIndex!]['name'] as String;

    // Navigate to HomeScreen with selected element
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(initialAttribute: selectedElement),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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

          // 2. Twinkling Stars (CustomPainter)
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
                    opacity: 0.2, // Requirement: 0.15-0.25
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
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                   // Top Spacer to push text to "upper center" relative to magic circle
                   // Magic circle is centered. Text should be above it.
                   // Assuming magic circle takes up substantial middle space.
                   // Let's position text at ~25% height.
                  SizedBox(height: size.height * 0.15),
                  
                  // Title Area
                  const Text(
                    "属性を選んでください",
                    style: TextStyle(
                      fontFamily: 'Roboto', // Or generic sans if Japanese logic needed
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose Your Element",
                    style: TextStyle(
                      fontFamily: 'Cinzel', // Ensure this font is valid or fallback
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: AppShadows.whiteSoft,
                    ),
                  ),

                  const Spacer(), // Pushes the rest to the bottom
                  
                  // Element Selection Row (Horizontal Scroll)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _elements.length,
                      itemBuilder: (context, index) {
                        final element = _elements[index];
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _ElementButton(
                             name: element['name'],
                             color: element['color'],
                             isSelected: isSelected,
                             onTap: () => _onElementSelected(index),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Summon Button
                  _SummonButton(
                    onTap: _selectedIndex != null ? _onSummonPressed : null,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------ UI Components ------

class _ElementButton extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ElementButton({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? 80 : 70,
        height: isSelected ? 80 : 70,
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color.withOpacity(0.3) : Colors.black26,
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  SafeBoxShadow.build(
                    color: color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple orb representation or text
            Container(
               width: isSelected ? 24 : 16,
               height: isSelected ? 24 : 16,
               decoration: BoxDecoration(
                 color: color,
                 shape: BoxShape.circle,
                 boxShadow: [
                    SafeBoxShadow.build(color: color, blurRadius: 10, spreadRadius: 2),
                 ],
               ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummonButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SummonButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap, // Ripple handled by InkWell if we used it, but GestureDetector allows custom implementation
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isEnabled ? 1.0 : 0.3,
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Deep Violet
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Colors.grey, Colors.black54],
                  ),
            boxShadow: isEnabled
                ? [
                    SafeBoxShadow.build(
                      color: const Color(0xFF7B1FA2).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            "精霊を召喚する",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: AppShadows.blackSoft,
            ),
          ),
        ),
      ),
    );
  }
}

// ------ Pairtner Classes ------

class _StarPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final List<Offset> _stars = [];

  _StarPainter(this.animationValue) {
    // Generate deterministic stars based on a fixed seed logic if needed
    // But for performance in paint(), usually state should hold star positions.
    // Here we strictly follow "CustomPainterで魔法陣を描画" style logic. 
    // To properly animate flickering, we'll generate stars once or use pseudo-random.
    // For simplicity & performance, we use a simple pseudo-random generator inside paint
    // wrapped with a consistent seed logic or generate in constructor.
    // Since constructor is called every frame in AnimatedBuilder, we should actually
    // move generation to State. BUT, for this snippet constraint, I will stick to
    // simple psudeo-random based on index in a loop.
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(12345); // Fixed seed for consistent positions

    for (int i = 0; i < 50; i++) {
        double x = random.nextDouble() * size.width;
        double y = random.nextDouble() * size.height;
        double baseSize = random.nextDouble() * 2 + 1;
        
        // Twinkle logic
        double twinkle = math.sin((animationValue * 2 * math.pi) + random.nextDouble() * 10);
        double opacity = (twinkle + 1) / 2 * 0.7 + 0.3; // 0.3 to 1.0

        paint.color = Colors.white.withOpacity(opacity);
        canvas.drawCircle(Offset(x, y), baseSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => true; // Re-paint for animation
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
      double angle = (i * 2 * math.pi / 6); // Offset start
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
    final rect = Rect.fromCenter(center: center, width: radius * 0.85, height: radius * 0.85);
    canvas.drawRect(rect, paint..strokeWidth = 1.0); // Actually this draws a square, not diamond unless rotated.
    // Let's draw a rotated square (Diamond)
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
