import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:track_me/core/theme.dart';
import 'package:track_me/data/database_helper.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/onboarding/onboarding_screen.dart';
import 'package:track_me/screens/shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _bootstrap();
  }

  void _initVideo() {
    final c = VideoPlayerController.asset('assets/video/Loading_screen.mp4');
    _controller = c;
    c
      ..setLooping(false)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        c.play();
        c.addListener(_onVideoProgress);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _videoReady = false);
        _videoFinished = true;
        if (_readyToNavigate) _navigate();
      });
  }

  void _onVideoProgress() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    final dur = c.value.duration;
    if (pos >= dur) {
      _videoFinished = true;
      if (_readyToNavigate) _navigate();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  bool _readyToNavigate = false;
  bool _videoFinished = false;

  Future<void> _bootstrap() async {
    await DatabaseHelper.instance.database;
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    await state.refreshNotifications();
    _readyToNavigate = true;
    if (_videoFinished) _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final state = Provider.of<AppState>(context, listen: false);
    final user = state.user;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => (!user.onboardingCompleted || user.name.isEmpty)
            ? const OnboardingScreen()
            : const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady)
            VideoPlayer(_controller!)
          else
            const _FallbackSplash(),
        ],
      ),
    );
  }
}

class _FallbackSplash extends StatelessWidget {
  const _FallbackSplash();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 1.5),
              ),
              child: const Icon(Icons.savings_outlined,
                  size: 52, color: AppColors.onHero),
            ),
            const SizedBox(height: 28),
            const Text(
              'TrackMe',
              style: TextStyle(
                color: AppColors.onHero,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your money, finally under control.',
              style: TextStyle(
                  color: AppColors.onHero.withValues(alpha: 0.85),
                  fontSize: 14),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.onHero.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
