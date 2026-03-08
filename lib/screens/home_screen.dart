import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:html' as html; // For Web Download
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final String? initialAttribute;

  const HomeScreen({super.key, this.initialAttribute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ==============================
// Generated Video Player
// ==============================
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
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _downloadVideo() {
    final anchor = html.AnchorElement(href: widget.videoUrl)
      ..setAttribute("download", "spirit_video.mp4")
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Container(
          height: 60,
          color: Colors.black.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
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
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _downloadVideo,
                tooltip: '保存する Save',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==============================
// Home Screen
// ==============================
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _mediaUrl;
  bool _isLoading = false;
  double _progress = 0.0;
  Timer? _timer;

  late final AnimationController _entryController;
  late final AnimationController _rotationController;
  late final AnimationController _starController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _starAnimation;

  String? _selectedAttribute;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

    _entryController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _starAnimation =
        CurvedAnimation(parent: _starController, curve: Curves.easeInOut);

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
  _timer?.cancel();

  setState(() {
    _mediaUrl = null;     // 動画表示だけ閉じる
    _isLoading = false;
    _progress = 0.0;
    // _selectedAttribute は消さない
  });
}

  void _startTimer() {
    _progress = 0.0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.95) _progress += 0.01;
      });
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream(User? user) {
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Future<void> _showLoginDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isSigningIn = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> signInWithGoogle() async {
              try {
                setLocalState(() => isSigningIn = true);

                final googleProvider = GoogleAuthProvider()
                  ..addScope('email')
                  ..setCustomParameters({'prompt': 'select_account'});

                final userCredential =
                    await _auth.signInWithPopup(googleProvider);

                final user = userCredential.user;
                if (user != null) {
                  await _ensureUserDocument(user);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('ログインに失敗しました Login failed: $e'),
                    ),
                  );
                }
              } finally {
                if (context.mounted) {
                  setLocalState(() => isSigningIn = false);
                }
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF101020),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ログインが必要です Login is required.',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '精霊の召喚にはログインが必要です。Login is required to summon spirits.\nGoogleアカウントでログインしてください。Please sign in with your Google account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSigningIn ? null : signInWithGoogle,
                        icon: isSigningIn
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          isSigningIn ? 'ログイン中...Logging in...' : 'Googleでログイン Sign in with Google',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isSigningIn
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        '閉じる Close',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _ensureUserDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'credits': 3,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = doc.data();
      if (data == null || !data.containsKey('credits')) {
        await userRef.set({
          'credits': 3,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _generateMedia() async {
    if (_selectedAttribute == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      await _showLoginDialog();
      return;
    }

    await _ensureUserDocument(user);

    setState(() {
      _isLoading = true;
      _mediaUrl = null;
    });

    _startTimer();

    try {
      final result = await _functions
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

      if (!mounted) return;

      if (url != null) {
        _timer?.cancel();
        setState(() {
          _progress = 1.0;
          _mediaUrl = url;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('動画URLの取得に失敗しました。Failed to retrieve the video URL.'),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = '精霊が姿を現しませんでした。もう一度召喚してください。The spirit did not appear. Please summon it again.';

      if (e.code == 'unauthenticated') {
        message = 'ログイン後に精霊を召喚できます。You can summon spirits after logging in.';
        await _showLoginDialog();
      } else if (e.code == 'failed-precondition') {
        message = '残りクレジットがありません。You have no remaining credits.';
      } else if (e.code == 'not-found') {
        message = 'ユーザー情報が見つかりませんでした。再ログインしてください。User information not found. Please log in again.';
      } else if (e.code == 'invalid-argument') {
        message = '送信内容が正しくありません。The content you sent is incorrect.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました。An error has occurred: $e'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;

    setState(() {
      _mediaUrl = null;
      _isLoading = false;
      _progress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ログアウトしました。You have logged out.'),
      ),
    );
  }

  void _onElementSelected(String name) {
    setState(() {
      _selectedAttribute = name;
    });
  }

  Widget _buildTopStatusBar() {
    return Positioned(
      top: 24,
      left: 20,
      right: 20,
      child: SafeArea(
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            final userStream = _userDocStream(user);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_mediaUrl != null && !_isLoading)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                    onPressed: _resetAll,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (user != null && userStream != null)
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: userStream,
                            builder: (context, creditSnapshot) {
                              final data = creditSnapshot.data?.data();
                              final credits = data?['credits'] ?? 0;

                              return _InfoChip(
                                icon: Icons.bolt,
                                label: 'Credits: $credits',
                              );
                            },
                          ),
                        const SizedBox(width: 10),
                        if (user != null)
                          PopupMenuButton<String>(
                            color: const Color(0xFF1A1A2E),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await _signOut();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'logout',
                                child: Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            child: _InfoChip(
                              icon: Icons.account_circle,
                              label:
                                  user.displayName ?? user.email ?? 'Login',
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showLoginDialog,
                            child: const _InfoChip(
                              icon: Icons.login,
                              label: 'Login',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCreditPill() {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return GestureDetector(
            onTap: _showLoginDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: const Text(
                "ログインして召喚を開始",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocStream(user),
          builder: (context, userDocSnapshot) {
            final data = userDocSnapshot.data?.data();
            final credits = data?['credits'] ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: Text(
                "残りクレジット: $credits",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_mediaUrl == null) ...[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF0A0A2A),
                    Color(0xFF1A1A3A),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _starAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _StarPainter(_starAnimation.value),
                );
              },
            ),
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

          if (_mediaUrl != null)
            Center(
              child: GeneratedVideoPlayer(videoUrl: _mediaUrl!),
            )
          else if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "最高画質で精霊を召喚中...3分ほどかかる場合があります。\nSummoning spirits at maximum quality...This may take up to 3 minutes.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.purpleAccent, blurRadius: 10)
                        ],
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
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.18),
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
                    const Text(
                      "Choose Your Element",
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(color: Colors.white54, blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildUserCreditPill(),
                    const Spacer(),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _elements.length,
                        itemBuilder: (context, index) {
                          final element = _elements[index];
                          final isSelected =
                              _selectedAttribute == element['name'];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
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
                    _SummonButton(
                      onTap:
                          _selectedAttribute != null ? _generateMedia : null,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

          _buildTopStatusBar(),

          if (_mediaUrl != null && !_isLoading)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: () =>
                    Share.share("精霊を召喚しました！ I summoned a spirit! $_mediaUrl"),
                child: const Icon(Icons.share),
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================
// Small Info Chip
// ==============================
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// UI Components
// ==============================
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
    final outerShadow = BoxShadow(
      color: isSelected ? color.withOpacity(0.6) : Colors.transparent,
      blurRadius: isSelected ? 20 : 0,
      spreadRadius: isSelected ? 2 : 0,
      offset: Offset.zero,
    );

    final innerGlow = BoxShadow(
      color: color.withOpacity(isSelected ? 1.0 : 0.7),
      blurRadius: isSelected ? 10 : 6,
      spreadRadius: isSelected ? 2 : 1,
      offset: Offset.zero,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? 80 : 70,
        height: isSelected ? 80 : 70,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color.withOpacity(0.3) : Colors.black26,
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [outerShadow],
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
                boxShadow: [innerGlow],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
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

    final buttonShadow = BoxShadow(
      color: isEnabled
          ? const Color(0xFF7B1FA2).withOpacity(0.5)
          : Colors.transparent,
      blurRadius: isEnabled ? 15 : 0,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    );

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
            boxShadow: [buttonShadow],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            "精霊を召喚する",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================
// Painters
// ==============================
class _StarPainter extends CustomPainter {
  final double animationValue;

  _StarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(12345);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final baseSize = random.nextDouble() * 2 + 1;

      final twinkle = math.sin(
        (animationValue * 2 * math.pi) + random.nextDouble() * 10,
      );
      final opacity = (twinkle + 1) / 2 * 0.7 + 0.3;

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
      final angle = (i * 2 * math.pi / 6) - (math.pi / 2);
      final x = center.dx + radius * 0.95 * math.cos(angle);
      final y = center.dy + radius * 0.95 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    final path2 = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * 2 * math.pi / 6;
      final x = center.dx + radius * 0.95 * math.cos(angle);
      final y = center.dy + radius * 0.95 * math.sin(angle);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
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

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 6);
      final x = center.dx + radius * 0.8 * math.cos(angle);
      final y = center.dy + radius * 0.8 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}