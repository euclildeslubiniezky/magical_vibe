import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

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

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String? _mediaUrl;
  bool _isLoading = false;
  double _progress = 0.0;
  Timer? _timer;
  String? _selectedAttribute;

  final List<Map<String, dynamic>> _attributes = [
    {'name': 'Fire', 'color': Colors.red},
    {'name': 'Water', 'color': Colors.blue},
    {'name': 'Thunder', 'color': Colors.amber},
    {'name': 'Ice', 'color': Colors.lightBlueAccent},
    {'name': 'Wind', 'color': Colors.green},
    {'name': 'Light', 'color': Colors.yellow},
    {'name': 'Dark', 'color': Colors.purple},
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _mediaUrl = null;
      _selectedAttribute = null;
      _isLoading = false;
    });
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
          .call({'attribute': _selectedAttribute});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // メイン表示エリア
          Center(
            child: _mediaUrl != null
                ? GeneratedVideoPlayer(videoUrl: _mediaUrl!)
                : Text(
                    _selectedAttribute == null
                        ? "属性を選んでください"
                        : "「召喚」を押して精霊を呼び出す",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white54,
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

          // シェアボタン
          if (_mediaUrl != null && !_isLoading)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: () =>
                    Share.share("精霊を召喚しました！ $_mediaUrl"),
                child: const Icon(Icons.share),
              ),
            ),

          // ローディング画面
          if (_isLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "最高画質で精霊を召喚中...\n3分ほどかかる場合があります。",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    CircularProgressIndicator(
                      value: _progress,
                      color: Colors.indigoAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${(_progress * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // 下部UI
          if (!_isLoading && _mediaUrl == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _attributes.length,
                      itemBuilder: (context, index) {
                        final attr = _attributes[index];
                        final isSelected =
                            _selectedAttribute == attr['name'];

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: Text(attr['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedAttribute = attr['name'];
                              });
                            },
                            selectedColor: attr['color'],
                            backgroundColor: Colors.grey.shade900,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white60,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 40, top: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _selectedAttribute == null
                          ? null
                          : _generateMedia,
                      child: const Text(
                        "精霊を召喚する",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
