import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/data_screen.dart';
import 'package:study_support_app/home_screen_folder/home_screen.dart';
import 'package:study_support_app/main.dart';
import 'home_screen_folder/home_screen.dart';
import 'data_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential =
        await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null || !mounted) return;

      // 開発中は毎回OnboardingScreenへ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    } catch (e, stackTrace) {
      print("❌ エラー発生");
      print(e);
      print(stackTrace);
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
