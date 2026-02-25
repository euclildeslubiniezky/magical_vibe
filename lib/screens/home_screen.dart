import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  final String? initialAttribute;
  const HomeScreen({super.key, this.initialAttribute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  String? _mediaUrl;
  String? _selectedAttribute;

  bool _isLoading = false;
  double _progress = 0.0;

  int _credits = 0;

  Timer? _progressTimer;
  StreamSubscription<DocumentSnapshot>? _jobSub;
  StreamSubscription<DocumentSnapshot>? _creditSub;

  final List<String> _elements = [
    'Fire','Water','Thunder','Ice','Wind','Light','Dark'
  ];

  @override
  void initState() {
    super.initState();
    _selectedAttribute = widget.initialAttribute;
    _listenToCredits();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _jobSub?.cancel();
    _creditSub?.cancel();
    super.dispose();
  }

  // ===============================
  // クレジット監視
  // ===============================
  void _listenToCredits() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _creditSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      setState(() {
        _credits = snapshot.data()?["credits"] ?? 0;
      });
    });
  }

  // ===============================
  // フェイク進捗
  // ===============================
  void _startFakeProgress() {
    _progressTimer?.cancel();
    _progress = 0.0;

    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) return;

      setState(() {
        if (_progress < 0.9) {
          _progress += 0.03;
        }
      });
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===============================
  // 動画生成
  // ===============================
  Future<void> _generate() async {
    if (_selectedAttribute == null) return;

    if (_credits <= 0) {
      _showError("クレジットが不足しています");
      return;
    }

    setState(() {
      _isLoading = true;
      _mediaUrl = null;
    });

    _startFakeProgress();

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateVideo');

      final result = await callable.call({
        "prompt": _selectedAttribute,
      });

      final jobId = result.data["jobId"];
      if (jobId == null) throw Exception("jobId null");

      _listenToJob(jobId);

    } catch (e) {
      _stopProgress();
      setState(() => _isLoading = false);
      _showError("生成開始に失敗しました");
    }
  }

  // ===============================
  // ジョブ監視
  // ===============================
  void _listenToJob(String jobId) {

    _jobSub?.cancel();

    _jobSub = FirebaseFirestore.instance
        .collection("videoJobs")
        .doc(jobId)
        .snapshots()
        .listen((snapshot) {

      if (!snapshot.exists) return;

      final data = snapshot.data();
      final status = data?["status"];

      if (status == "completed") {

        _stopProgress();

        setState(() {
          _mediaUrl = data?["videoUrl"];
          _progress = 1.0;
          _isLoading = false;
        });

        _jobSub?.cancel();
      }

      if (status == "failed") {

        _stopProgress();
        setState(() => _isLoading = false);

        _showError("動画生成に失敗しました");
        _jobSub?.cancel();
      }
    });
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Spirit Generator"),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Credits: $_credits",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: _isLoading
            ? _buildLoading()
            : _mediaUrl != null
                ? GeneratedVideoPlayer(videoUrl: _mediaUrl!)
                : _buildSelector(),
      ),
    );
  }

  Widget _buildSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Wrap(
          spacing: 10,
          children: _elements.map((e) {
            final selected = _selectedAttribute == e;
            return ChoiceChip(
              label: Text(e),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _selectedAttribute = e),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed:
              _selectedAttribute != null ? _generate : null,
          child: const Text("Generate"),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(value: _progress),
        const SizedBox(height: 20),
        Text(
          "${(_progress * 100).toInt()}%",
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

// ===============================
// Video Player
// ===============================
class GeneratedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const GeneratedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<GeneratedVideoPlayer> createState() =>
      _GeneratedVideoPlayerState();
}

class _GeneratedVideoPlayerState
    extends State<GeneratedVideoPlayer> {

  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
            _controller.setLooping(true);
            _controller.play();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _download() {
    final anchor = html.AnchorElement(href: widget.videoUrl)
      ..setAttribute("download", "spirit_video.mp4")
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Container(
          height: 60,
          color: Colors.black54,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
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
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download,
                    color: Colors.white),
                onPressed: _download,
              ),
            ],
          ),
        )
      ],
    );
  }
}