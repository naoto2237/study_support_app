// ======================================================================
// 【画面】起動画面（スプラッシュ）
//
// 主なクラス: SplashScreen
// 開き方: main.dart の AppStartScreen（未ログイン・未登録のとき）
// ・はじめの画面（welcome_screen.dart）へ進む
//   （ゲストではじめるか、Google で続けるかは、そこでえらんでもらう）
// ======================================================================

import 'package:flutter/material.dart';

import 'package:study_support_app/screens/start/welcome_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 画面を1回描いてから、はじめの画面へ置きかえる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
