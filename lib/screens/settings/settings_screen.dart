// ======================================================================
// 【画面】設定
//
// 主なクラス: SettingsScreen
// 開き方: マイページの設定アイコン
// ・ダークモード（行のスイッチで、その場で切りかえる）
// ・学習記録の公開／非公開（行のスイッチで、その場で切りかえて保存する）
// ・使い方ガイド
// ・ログアウト（確かめてから、サインアウトして初回登録画面へ）
// ・見た目はほかの画面とそろえて、白いカード（枠つき・角丸16）を並べる
// ・旧ファイル名: setting_screen.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart'; // main.dart の isDarkModeNotifier を使う
import 'package:study_support_app/screens/start/onboarding_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 学習記録を公開しているか
  bool _isPublic = true;

  // 公開設定を読み込み中か・保存中か
  bool _isLoadingPrivacy = true;
  bool _isSavingPrivacy = false;

  // ログアウトなど、危ない操作の赤
  static const Color _red = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  // ==============================================================
  // 公開設定の読み込み・保存
  // ==============================================================

  Future<void> _loadPrivacySetting() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();

        if (data != null && data.containsKey('isPublic') && mounted) {
          setState(() {
            _isPublic = data['isPublic'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('公開設定の取得に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrivacy = false;
        });
      }
    }
  }

  // スイッチを切りかえたら、すぐに保存する
  // （失敗したときだけ、元に戻して知らせる）
  Future<void> _setPublic(bool value) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final previous = _isPublic;

    setState(() {
      _isPublic = value;
      _isSavingPrivacy = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPublic': value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('公開設定の保存に失敗しました: $e');

      if (!mounted) return;

      setState(() {
        _isPublic = previous;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('設定を保存できませんでした')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPrivacy = false;
        });
      }
    }
  }

  // ==============================================================
  // ログアウト（確かめてから）
  // ==============================================================

  Future<void> _confirmLogout() async {
    final p = context.pal;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ログアウトしますか？',
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'もう一度使うときは、ログインし直す必要があります。',
            style: TextStyle(color: p.secondary, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('キャンセル', style: TextStyle(color: p.secondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'ログアウト',
                style: TextStyle(color: _red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // ログイン画面（OnboardingScreen）へ置きかえて移る
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } catch (e, stackTrace) {
      debugPrint('ログアウトに失敗しました: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // ==============================================================
  // 使い方ガイド
  // ==============================================================

  void _showGuideDialog() {
    final p = context.pal;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '使い方ガイド',
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _guideItem(
                  icon: Icons.home_rounded,
                  title: 'ホーム',
                  description: '学習タイマーで、毎日の学習時間を測ります。曜日ごとの目標も決められます。',
                ),
                _guideItem(
                  icon: Icons.auto_awesome,
                  title: 'AIサポート',
                  description: '勉強の疑問や分からないことをAIに質問できます。',
                ),
                _guideItem(
                  icon: Icons.diversity_3,
                  title: 'Link',
                  description: '学習仲間を探したり、Q&Aやルームで交流したりできます。',
                ),
                _guideItem(
                  icon: Icons.bar_chart_rounded,
                  title: '学習記録',
                  description: 'これまでの学習時間をグラフで振り返り、他の人と比べられます。',
                ),
                _guideItem(
                  icon: Icons.person_rounded,
                  title: 'マイページ・設定',
                  description: 'プロフィールの確認・編集や、アプリの設定ができます。',
                  isLast: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '閉じる',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _guideItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    final p = context.pal;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(icon, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: p.secondary,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 共通の部品
  // ==============================================================

  // うすい青の角丸の四角にのせたアイコン（Link のメニューと同じ形）
  Widget _iconBox(IconData icon, {double size = 40, Color? color}) {
    final p = context.pal;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == null ? p.primarySoft : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, size: size * 0.55, color: color ?? AppColors.primary),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.pal.secondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    final p = context.pal;

    final children = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);

      if (i != rows.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, indent: 68, color: p.divider),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
      ),
    );
  }

  // 設定の1行（左にアイコン、まん中に名前と説明、右にスイッチか「>」）
  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    final p = context.pal;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? p.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.secondary, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool>? onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
    );
  }

  // ==============================================================
  // build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    // ダークモードを切りかえたら、この画面もすぐ描き直す
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        final p = context.pal;

        return Scaffold(
          backgroundColor: p.page,
          appBar: AppBar(
            title: Transform.translate(
              offset: const Offset(-18, 0),
              child: Text(
                '設定',
                style: TextStyle(
                  color: p.text,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: p.card,
            iconTheme: IconThemeData(color: p.text),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 32),
            children: [
              // ------------------------------------------
              // アプリの設定
              // ------------------------------------------
              _sectionTitle('アプリの設定'),
              _card([
                _row(
                  icon: Icons.dark_mode_outlined,
                  title: 'ダークモード',
                  subtitle: isDark ? '暗い色の画面にしています' : '明るい色の画面にしています',
                  trailing: _switch(
                    isDark,
                    (value) => isDarkModeNotifier.value = value,
                  ),
                  onTap: () => isDarkModeNotifier.value = !isDark,
                ),
                _row(
                  icon: _isPublic
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  title: '学習記録を公開する',
                  subtitle: _isLoadingPrivacy
                      ? '読み込み中…'
                      : (_isPublic
                            ? '他のユーザーも、あなたの学習記録を見られます'
                            : '学習記録は、あなただけが見られます'),
                  trailing: _switch(
                    _isPublic,
                    (_isLoadingPrivacy || _isSavingPrivacy) ? null : _setPublic,
                  ),
                  onTap: (_isLoadingPrivacy || _isSavingPrivacy)
                      ? null
                      : () => _setPublic(!_isPublic),
                ),
              ]),

              const SizedBox(height: 24),

              // ------------------------------------------
              // アプリについて
              // ------------------------------------------
              _sectionTitle('アプリについて'),
              _card([
                _row(
                  icon: Icons.help_outline_rounded,
                  title: '使い方ガイド',
                  subtitle: 'それぞれの画面でできること',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: p.muted,
                    size: 24,
                  ),
                  onTap: _showGuideDialog,
                ),
              ]),

              const SizedBox(height: 24),

              // ------------------------------------------
              // アカウント
              // ------------------------------------------
              _sectionTitle('アカウント'),
              _card([
                _row(
                  icon: Icons.logout_rounded,
                  title: 'ログアウト',
                  color: _red,
                  onTap: _confirmLogout,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}
