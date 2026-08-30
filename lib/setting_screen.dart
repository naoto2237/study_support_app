import 'package:cloud_firestore/cloud_firestore.dart'; // 追加: Firestore用
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart'; // main.dart の isDarkModeNotifier などを読み込む
import 'data_screen.dart'; // OnboardingScreen があるファイル

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 学習記録の公開設定の選択状態（'public' = 公開, 'private' = 非公開）
  String _selectedPrivacyOption = 'public';
  bool _isLoadingPrivacy = true; // 読み込み中の状態管理

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting(); // 起動時にFirebaseから現在の設定を取得
  }

  // Firebaseから現在の公開設定を取得する処理
  Future<void> _loadPrivacySetting() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('isPublic')) {
            setState(() {
              // 'isPublic'がtrueなら'public'、falseなら'private'
              _selectedPrivacyOption = (data['isPublic'] == true) ? 'public' : 'private';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 公開設定の取得に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrivacy = false;
        });
      }
    }
  }

  // ダークモード・ライトモード選択ダイアログ
  void _showThemeSettingsDialog(BuildContext context) {
    bool tempThemeOption = isDarkModeNotifier.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('ダークモード設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    title: const Text('ライト（通常）'),
                    subtitle: const Text('明るい背景のテーマ'),
                    value: false,
                    groupValue: tempThemeOption,
                    activeColor: Colors.blue,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        tempThemeOption = value!;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('ダーク（暗黒い感じ）'),
                    subtitle: const Text('暗めの落ち着いたテーマ'),
                    value: true,
                    groupValue: tempThemeOption,
                    activeColor: Colors.blue,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        tempThemeOption = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    isDarkModeNotifier.value = tempThemeOption;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isDarkModeNotifier.value ? 'ダークモードに切り替えました' : 'ライトモードに切り替えました')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 学習記録の公開設定ダイアログ（Firebase連携版）
  void _showPrivacySettingsDialog(BuildContext context) {
    String tempPrivacyOption = _selectedPrivacyOption;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('学習記録の公開設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('公開する'),
                    subtitle: const Text('他のユーザーに学習記録を見せる'),
                    value: 'public',
                    groupValue: tempPrivacyOption,
                    activeColor: Colors.blue,
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempPrivacyOption = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('非公開にする'),
                    subtitle: const Text('自分だけが学習記録を確認できる'),
                    value: 'private',
                    groupValue: tempPrivacyOption,
                    activeColor: Colors.blue,
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempPrivacyOption = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // ダイアログを閉じる

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        bool isPublicValue = (tempPrivacyOption == 'public');

                        // Firestoreの users/{uid} ドキュメントを更新（存在しない場合は作成）
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'isPublic': isPublicValue,
                        }, SetOptions(merge: true));

                        setState(() {
                          _selectedPrivacyOption = tempPrivacyOption;
                        });

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_selectedPrivacyOption == 'public'
                                ? '学習記録を公開に設定しました'
                                : '学習記録を非公開に設定しました'),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('❌ 公開設定の保存に失敗しました: $e');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('設定の保存に失敗しました')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 使い方ガイドを表示するダイアログ
  void _showGuideDialog(BuildContext context) {
    final bool isDark = isDarkModeNotifier.value;
    final dialogBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '📖 使い方ガイド',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _guideItem(
                  icon: Icons.home,
                  title: '1. ホーム画面',
                  description: 'ストップウォッチ機能を使って、毎日の学習時間を測ることができます。',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _guideItem(
                  icon: Icons.auto_awesome,
                  title: '2. AIサポート',
                  description: '勉強の疑問点や分からないことをAIに質問して、効率よく学習を進めることができます。',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _guideItem(
                  icon: Icons.diversity_3,
                  title: '3. Link',
                  description: '他の学習仲間とつながり、モチベーションを高め合うことができるコミュニティ機能です。',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _guideItem(
                  icon: Icons.bar_chart,
                  title: '4. 学習記録',
                  description: 'これまでの学習時間や記録をグラフで振り返り、日々の成果を確認できます。',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _guideItem(
                  icon: Icons.person,
                  title: '5. マイページ・設定',
                  description: 'プロフィールの確認や、ダークモードなどのアプリの設定を変更できます。',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
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
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 12, color: subTextColor)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white70 : Colors.black87;
        final subTextColor = isDark ? Colors.white54 : Colors.grey;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              '設定',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            elevation: 0,
            backgroundColor: cardColor,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- ■ アプリ設定 ---
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'アプリ設定',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined, color: Colors.blue),
                      title: Text('ダークモード', style: TextStyle(color: textColor)),
                      subtitle: Text(isDark ? 'ダーク（暗黒い感じ）' : 'ライト（通常）', style: TextStyle(fontSize: 12, color: subTextColor)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _showThemeSettingsDialog(context),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Colors.blue),
                      title: Text('学習記録の公開', style: TextStyle(color: textColor)),
                      subtitle: Text(
                        _isLoadingPrivacy
                            ? '読み込み中...'
                            : (_selectedPrivacyOption == 'public' ? '公開する' : '非公開にする'),
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _showPrivacySettingsDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- ■ アプリについて ---
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'アプリについて',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.blue),
                  title: Text('使い方ガイド', style: TextStyle(color: textColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showGuideDialog(context),
                ),
              ),

              const SizedBox(height: 32),

              // --- ログアウトボタン ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          try {
                            // 1. Firebaseからサインアウト
                            await FirebaseAuth.instance.signOut();

                            if (!context.mounted) return;

                            // 2. ログイン画面（OnboardingScreen）へ置き換え遷移
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
                        },
                        child: const Text('ログアウトする'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}