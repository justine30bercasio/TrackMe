import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _readyToNavigate = false;
  bool _navigated = false;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await DatabaseHelper.instance.database;
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    await state.refreshNotifications();
    _readyToNavigate = true;
    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted || !_readyToNavigate) return;
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
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: Tween(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
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