import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:html' as html; // For Web Download
import 'dart:math' as math;
import '../theme/app_shadows.dart';

class HomeScreen extends StatefulWidget {
  final String? initialAttribute;

  const HomeScreen({super.key, this.initialAttribute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// GeneratedVideoPlayer with Custom Controls & Web Download
class GeneratedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const GeneratedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<GeneratedVideoPlayer> createState() => _GeneratedVideoPlayerState();
}

class _GeneratedVideoPlayerState extends State<GeneratedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true); // Default looping
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _downloadVideo() {
    // Web download logic: Direct download without opening new tabs
    final anchor = html.AnchorElement(href: widget.videoUrl)
      ..setAttribute("download", "spirit_video.mp4")
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Video Layer
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),

        // 2. Custom Controls Layer (Always Visible)
        Container(
          height: 60,
          color: Colors.black.withOpacity(0.6), // Semi-transparent black background
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Play/Pause Button
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              
              // Progress Bar
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.purpleAccent,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
              
              // Download Button
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _downloadVideo,
                tooltip: '保存する',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _mediaUrl;
  bool _isLoading = false;
  double _progress = 0.0;
  Timer? _timer;
  
  // Animation Controllers for UI
  late final AnimationController _entryController;
  late final AnimationController _rotationController;
  late final AnimationController _starController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _starAnimation;

  String? _selectedAttribute;

  final List<Map<String, dynamic>> _elements = [
    {'name': 'Fire', 'color': const Color(0xFFFF4500)},
    {'name': 'Water', 'color': const Color(0xFF2196F3)},
    {'name': 'Thunder', 'color': const Color(0xFFFFD700)},
    {'name': 'Ice', 'color': const Color(0xFF00FFFF)},
    {'name': 'Wind', 'color': const Color(0xFF00E676)},
    {'name': 'Light', 'color': const Color(0xFFFFF176)},
    {'name': 'Dark', 'color': const Color(0xFF9C27B0)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAttribute != null) {
      _selectedAttribute = widget.initialAttribute;
    }

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

    // 4. Pulse
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _entryController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _rotationController.dispose();
    _starController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _mediaUrl = null;
      _isLoading = false;
    });
    if (!_entryController.isAnimating) {
        _entryController.forward(from: 0.0);
    }
  }

  void _startTimer() {
    _progress = 0.0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_progress < 0.95) _progress += 0.01;
      });
    });
  }

  Future<void> _generateMedia() async {
    if (_selectedAttribute == null) return;

    setState(() {
      _isLoading = true;
      _mediaUrl = null;
    });

    _startTimer();

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
            'generateTransformationVideo',
            options: HttpsCallableOptions(
              timeout: const Duration(minutes: 10),
            ),
          )
          .call({
            'attribute': _selectedAttribute,
            'duration': 5, 
          });

      final url = result.data['videoUrl'];

      if (url != null) {
        _timer?.cancel();
        setState(() {
          _progress = 1.0;
          _mediaUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      _timer?.cancel();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('精霊が姿を現しませんでした。もう一度召喚してください。'),
        ),
      );
    }
  }

  void _onElementSelected(String name) {
    setState(() {
      _selectedAttribute = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background components visible during selection or loading
          if (_mediaUrl == null) ...[
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

              // 3. Rotating Magic Circle
              Center(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Opacity(
                        opacity: 0.2,
                        child: CustomPaint(
                          size: const Size(600, 600),
                          painter: _MagicCirclePainter(),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
          
          // Foreground
          if (_mediaUrl != null)
            Center(
              child: GeneratedVideoPlayer(videoUrl: _mediaUrl!),
            )
          else if (_isLoading)
            // ローディング画面
            Container(
              color: Colors.black.withOpacity(0.5), 
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "最高画質で精霊を召喚中...\n3分ほどかかる場合があります。",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: AppShadows.purpleGlow,
                      ),
                    ),
                    const SizedBox(height: 40),
                    CircularProgressIndicator(
                      value: _progress,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${(_progress * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          else
            // 下部UI (Element Selection)
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.15),
                    
                    // Title Area
                    const Text(
                      "属性を選んでください",
                      style: TextStyle(
                        fontFamily: 'Roboto', 
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose Your Element",
                      style: TextStyle(
                        fontFamily: 'Cinzel', 
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: AppShadows.whiteSoft,
                      ),
                    ),

                    const Spacer(), 
                    
                    // Element Selection Row
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _elements.length,
                        itemBuilder: (context, index) {
                          final element = _elements[index];
                          final isSelected = _selectedAttribute == element['name'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _ElementButton(
                               name: element['name'],
                               color: element['color'],
                               isSelected: isSelected,
                               onTap: () => _onElementSelected(element['name']),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Summon Button
                    _SummonButton(
                      onTap: _selectedAttribute != null ? _generateMedia : null,
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

          // 戻るボタン
          if (_mediaUrl != null && !_isLoading)
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: _resetAll,
              ),
            ),

          // 保存ボタン
          if (_mediaUrl != null && !_isLoading)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: () {
                  if (_mediaUrl != null) {
                    html.window.open(_mediaUrl!, '_blank');
                    }
                  },
                child: const Icon(Icons.download),
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
      onTap: onTap,
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
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], 
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

// ------ Painters ------

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

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.95, paint);

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

    canvas.drawCircle(center, radius * 0.6, paint);
    
    final pathDiamond = Path();
    pathDiamond.moveTo(center.dx, center.dy - radius * 0.6);
    pathDiamond.lineTo(center.dx + radius * 0.6, center.dy);
    pathDiamond.lineTo(center.dx, center.dy + radius * 0.6);
    pathDiamond.lineTo(center.dx - radius * 0.6, center.dy);
    pathDiamond.close();
    canvas.drawPath(pathDiamond, paint);

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
