import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUser();
    });
  }

  Future<void> checkUser() async {
    // すでに遷移処理をしていたら何もしない
    if (_isNavigating) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential =
        await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null || !mounted) return;

      // 遷移開始を記録
      _isNavigating = true;

      // 開発中は毎回OnboardingScreenへ
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ エラー発生');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}