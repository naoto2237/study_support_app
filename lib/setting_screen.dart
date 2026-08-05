import 'package:flutter/material.dart';

// ★ ホーム画面と共有する目標時間（初期値 3.0時間）
final ValueNotifier<double> dailyTargetHours = ValueNotifier<double>(3.0);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 通知設定の選択状態（'all' = すべての通知, 'off' = オフ）
  String _selectedNotificationOption = 'all';

  // ダークモード・ライトモードの選択状態（false = ライト, true = ダーク）
  bool _isDarkMode = false;

  // 学習記録の公開設定の選択状態（'public' = 公開, 'private' = 非公開）
  String _selectedPrivacyOption = 'public';

  // 1日の目標時間を変更するダイアログ
  void _showTargetTimeDialog(BuildContext context) {
    // 現在の目標の数値を初期値としてテキストコントローラにセット
    final TextEditingController controller = TextEditingController(
      text: dailyTargetHours.value.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('1日の目標時間の設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1日の目標とする学習時間（時間）を入力してください。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '例: 3 または 3.5',
                  suffixText: '時間',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
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
                // ★ 入力されたテキストを数字（double）に変換して共有変数に保存
                double? newTarget = double.tryParse(controller.text);
                if (newTarget != null && newTarget > 0) {
                  dailyTargetHours.value = newTarget;
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('目標時間を ${dailyTargetHours.value}時間 に設定しました')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 通知設定ダイアログ（ラジオボタン）
  void _showNotificationSettingsDialog(BuildContext context) {
    String tempSelectedOption = _selectedNotificationOption;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('通知設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('すべての通知を受け取る'),
                    subtitle: const Text('リマインダーや他のユーザーからの通知'),
                    value: 'all',
                    groupValue: tempSelectedOption,
                    activeColor: Colors.blue,
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempSelectedOption = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('通知をオフにする'),
                    subtitle: const Text('すべての通知を停止'),
                    value: 'off',
                    groupValue: tempSelectedOption,
                    activeColor: Colors.blue,
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempSelectedOption = value!;
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
                    setState(() {
                      _selectedNotificationOption = tempSelectedOption;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('通知設定を更新しました')),
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

  // ダークモード・ライトモード選択ダイアログ（ラジオボタン）
  void _showThemeSettingsDialog(BuildContext context) {
    bool tempThemeOption = _isDarkMode;

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
                    setState(() {
                      _isDarkMode = tempThemeOption;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isDarkMode ? 'ダークモードに切り替えました' : 'ライトモードに切り替えました')),
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

  // 学習記録の公開設定ダイアログ（ラジオボタン）
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
                  onPressed: () {
                    setState(() {
                      _selectedPrivacyOption = tempPrivacyOption;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_selectedPrivacyOption == 'public' ? '学習記録を公開に設定しました' : '学習記録を非公開に設定しました')),
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

  // 使い方ガイドを表示するダイアログ
  void _showGuideDialog(BuildContext context) {
    final bool isDark = _isDarkMode;
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
                  description: 'ストップウォッチ機能を使って、毎日の学習時間を測ることができます。目標時間に向かって頑張りましょう！',
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
                  description: 'プロフィールの確認や、目標時間・ダークモード・通知などのアプリの設定を変更できます。',
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

  // ガイド内の項目を表示するためのパーツ用ウィジェット
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
    final bool isDark = _isDarkMode;
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
          // --- ■ 学習・目標 ---
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              '学習・目標',
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
            child: ValueListenableBuilder<double>(
              valueListenable: dailyTargetHours,
              builder: (context, targetValue, child) {
                return ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.blue),
                  title: Text('1日の目標時間', style: TextStyle(color: textColor)),
                  subtitle: Text('現在の設定: ${targetValue}時間', style: TextStyle(fontSize: 12, color: subTextColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showTargetTimeDialog(context),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

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
                  leading: const Icon(Icons.notifications_outlined, color: Colors.blue),
                  title: Text('通知設定', style: TextStyle(color: textColor)),
                  subtitle: Text('タップして変更', style: TextStyle(fontSize: 12, color: subTextColor)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showNotificationSettingsDialog(context),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
                  subtitle: Text(_selectedPrivacyOption == 'public' ? '公開する' : '非公開にする', style: TextStyle(fontSize: 12, color: subTextColor)),
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

          // --- ログアウト・アカウント消去ボタン ---
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
                    onPressed: () {
                      // ログアウト処理
                    },
                    child: const Text('ログアウトする'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () {
                      // アカウント消去処理
                    },
                    child: const Text('アカウントを消去する'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}