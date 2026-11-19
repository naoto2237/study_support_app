// ======================================================================
// 【画面】はじめの画面（ゲストではじめるか、Google で続けるかをえらぶ）
//
// 主なクラス: WelcomeScreen
// 開き方: 起動画面（splash_screen.dart）／設定画面（ログアウト・アカウント削除のあと）
// ・「Google で続ける」
//     前に使っていた Google アカウント → そのアカウントに戻って、ホームへ
//     はじめての Google アカウント   → 連携した状態で、プロフィール入力（onboarding_screen.dart）へ
// ・「ゲストではじめる」
//     名前のないアカウント（匿名ログイン）で、プロフィール入力へ
//     （あとから、設定の「Google と連携」で連携できる）
// ・うまくいかなかったことは、ボタンの上に赤い文字で出す
// ======================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart' show MainNavigationScreen;
import 'package:study_support_app/screens/start/onboarding_screen.dart';
import 'package:study_support_app/services/google_account.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color _blue = AppColors.primary;

  // どちらのボタンを処理中か（処理中は、両方とも押せない）
  bool _isGoogleBusy = false;
  bool _isGuestBusy = false;

  String? _errorText;

  bool get _isBusy => _isGoogleBusy || _isGuestBusy;

  // プロフィール入力へ
  void _goToProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  // ======================================================
  // Google で続ける
  // ======================================================

  Future<void> _continueWithGoogle() async {
    if (_isBusy) return;

    setState(() {
      _isGoogleBusy = true;
      _errorText = null;
    });

    try {
      final registered = await GoogleAccount.signIn();

      if (!mounted) return;

      // アカウントをえらばずに閉じた
      if (registered == null) return;

      if (registered) {
        // 前に使っていたアカウントに戻れたので、そのままホームへ
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (_) => false,
        );
        return;
      }

      // はじめての Google アカウント → プロフィールを入れてもらう
      _goToProfile();
    } on GoogleAccountException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } catch (e) {
      debugPrint("Google で続けられませんでした: $e");
      if (mounted) {
        setState(() => _errorText = "Google でログインできませんでした。もう一度お試しください");
      }
    } finally {
      if (mounted) setState(() => _isGoogleBusy = false);
    }
  }

  // ======================================================
  // ゲストではじめる
  // ======================================================

  Future<void> _startAsGuest() async {
    if (_isBusy) return;

    setState(() {
      _isGuestBusy = true;
      _errorText = null;
    });

    try {
      // まだログインしていなければ、名前のないアカウントを作る
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      if (!mounted) return;

      _goToProfile();
    } catch (e) {
      debugPrint("ゲストではじめられませんでした: $e");
      if (mounted) {
        setState(() => _errorText = "はじめられませんでした。通信の状態を確かめて、もう一度お試しください");
      }
    } finally {
      if (mounted) setState(() => _isGuestBusy = false);
    }
  }

  // ======================================================
  // 見た目
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // パソコンの広い画面でも、横に広がりすぎないようにする
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------------------------------------------
                  // アプリの名前とひとこと
                  // ------------------------------------------
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: _blue,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Study-Link",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "勉強の時間を記録して、\n友達といっしょにがんばろう",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: p.secondary,
                    ),
                  ),

                  const SizedBox(height: 48),

                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // ------------------------------------------
                  // Google で続ける（おすすめ）
                  // ------------------------------------------
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _continueWithGoogle,
                      icon: _isGoogleBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text(
                        "Google で続ける",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _blue.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "機種を変えても、データを引きつげます。\n前に使っていたアカウントにも戻れます",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: p.secondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // ゲストではじめる
                  // ------------------------------------------
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _startAsGuest,
                      icon: _isGuestBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _blue,
                              ),
                            )
                          : const Icon(Icons.person_outline_rounded),
                      label: const Text(
                        "ゲストではじめる",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        backgroundColor: p.card,
                        side: const BorderSide(color: _blue, width: 1.5),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "あとから、設定で Google と連携できます",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: p.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
