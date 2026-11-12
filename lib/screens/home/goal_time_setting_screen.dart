// ======================================================================
// 【画面】曜日ごとの目標時間の設定
//
// 主なクラス: GoalTimeSettingScreen
// 開き方: ホーム画面の「曜日ごとの目標を設定」ボタン
// ・月〜日の目標時間（分）を選び、Firestore の users に保存する
// ・旧ファイル名: goaltime_setting_screen.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/main.dart' as app;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';

class GoalTimeSettingScreen extends StatefulWidget {
  const GoalTimeSettingScreen({super.key});

  @override
  State<GoalTimeSettingScreen> createState() => _GoalTimeSettingScreenState();
}

class _GoalTimeSettingScreenState extends State<GoalTimeSettingScreen> {
  static const Color primaryBlue = AppColors.primary;

  final List<String> weekdays = const [
    '月曜日',
    '火曜日',
    '水曜日',
    '木曜日',
    '金曜日',
    '土曜日',
    '日曜日',
  ];

  // 月〜日の目標時間（分）
  List<int> goalMinutes = List<int>.filled(7, 0);

  // 全曜日に設定する時間
  int sameTimeMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // ==============================================================
  // 保存済みの目標時間を読み込む
  // ==============================================================

  Future<void> _loadGoals() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    if (data == null) return;

    final goaltime = data['goaltime'] as Map<String, dynamic>?;

    if (goaltime == null) return;

    final loadedGoals = [
      (goaltime['monday'] as num?)?.toInt() ?? 0,
      (goaltime['tuesday'] as num?)?.toInt() ?? 0,
      (goaltime['wednesday'] as num?)?.toInt() ?? 0,
      (goaltime['thursday'] as num?)?.toInt() ?? 0,
      (goaltime['friday'] as num?)?.toInt() ?? 0,
      (goaltime['saturday'] as num?)?.toInt() ?? 0,
      (goaltime['sunday'] as num?)?.toInt() ?? 0,
    ];

    if (!mounted) return;

    setState(() {
      goalMinutes = loadedGoals;
    });
  }

  // ==============================================================
  // 時間選択
  // ==============================================================

  Future<void> _selectTime({
    required int currentMinutes,
    required ValueChanged<int> onSelected,
  }) async {
    int selectedHours = currentMinutes ~/ 60;
    int selectedMinutes = currentMinutes % 60;

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempHours = selectedHours;
        int tempMinutes = selectedMinutes;

        final hourController = FixedExtentScrollController(
          initialItem: selectedHours,
        );

        final minuteController = FixedExtentScrollController(
          initialItem: selectedMinutes,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 上のバー
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '目標時間を設定',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // 時間・分 Picker
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 時間
                        SizedBox(
                          width: 90,
                          height: 150,
                          child: ListWheelScrollView.useDelegate(
                            controller: hourController,
                            itemExtent: 45,
                            perspective: 0.002,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempHours = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 25,
                              builder: (context, index) {
                                final isSelected = index == tempHours;

                                return Center(
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      fontSize: isSelected ? 25 : 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        const Text(
                          '時間',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 18),

                        // 分
                        SizedBox(
                          width: 90,
                          height: 150,
                          child: ListWheelScrollView.useDelegate(
                            controller: minuteController,
                            itemExtent: 45,
                            perspective: 0.002,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempMinutes = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (context, index) {
                                final isSelected = index == tempMinutes;

                                return Center(
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      fontSize: isSelected ? 25 : 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        const Text(
                          '分',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 選択中の時間
                    Text(
                      tempHours == 0 && tempMinutes == 0
                          ? '未設定'
                          : '$tempHours時間$tempMinutes分',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 設定する
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempHours * 60 + tempMinutes);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          // 両端が丸いボタン
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          '適用する',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 未設定
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 0);
                      },
                      child: const Text(
                        '目標時間を未設定にする',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      onSelected(result);
    }
  }

  // ==============================================================
  // 全曜日に同じ時間を設定
  // ==============================================================

  /*void _applySameTime() {
    setState(() {
      goalMinutes = List<int>.filled(7, sameTimeMinutes);
    });
  }*/

  // ==============================================================
  // 保存
  // ==============================================================

  Future<void> _saveGoals() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final goaltime = {
      'monday': goalMinutes[0],
      'tuesday': goalMinutes[1],
      'wednesday': goalMinutes[2],
      'thursday': goalMinutes[3],
      'friday': goalMinutes[4],
      'saturday': goalMinutes[5],
      'sunday': goalMinutes[6],
    };

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'goaltime': goaltime,
    }, SetOptions(merge: true));

    // 今日の目標をすぐホーム画面にも反映
    final todayMinutes = goalMinutes[DateTime.now().weekday - 1];

    app.dailyTargetHours.value = todayMinutes / 60.0;

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ==============================================================
  // UI
  // ==============================================================

  // 曜日ごとの色（土曜は青、日曜は赤、それ以外は黒）
  static const Color _sundayRed = Color(0xFFE53935);

  Color _dayColor(int index) {
    if (index == 6) return _sundayRed;
    if (index == 5) return primaryBlue;
    return context.pal.text;
  }

  // 「1時間30分」のような時間を、数字は大きく・単位は小さく表示する
  List<TextSpan> _timeSpans(
    int minutes,
    Color color, {
    double numberSize = 17,
    double unitSize = 11,
  }) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;

    TextSpan number(String text) => TextSpan(
      text: text,
      style: GoogleFonts.roboto(
        fontSize: numberSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );

    TextSpan unit(String text) => TextSpan(
      text: text,
      style: TextStyle(
        fontSize: unitSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );

    return [
      if (hours > 0) ...[number('$hours'), unit('時間')],
      if (rest > 0 || hours == 0) ...[number('$rest'), unit('分')],
    ];
  }

  // 時間の表示（設定済みは青の太字、未設定は灰色）
  Widget _buildTimeValue(int minutes, {double numberSize = 17}) {
    if (minutes <= 0) {
      return Text(
        '未設定',
        style: TextStyle(fontSize: 14, color: context.pal.muted),
      );
    }

    return Text.rich(
      TextSpan(
        children: _timeSpans(minutes, primaryBlue, numberSize: numberSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyTotal = goalMinutes.fold<int>(
      0,
      (total, value) => total + value,
    );

    return Scaffold(
      backgroundColor: context.pal.page,

      // ============================================================
      // AppBar
      // ============================================================
      appBar: AppBar(
        backgroundColor: context.pal.card,
        elevation: 0,
        titleSpacing: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.pal.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Transform.translate(
          offset: const Offset(-2, 0),
          child: Text(
            '曜日ごとの目標設定',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: context.pal.text,
            ),
          ),
        ),
      ),

      // ============================================================
      // Body（画面が小さくても下まで見られるよう、スクロールできる）
      // ============================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '曜日ごとに学習目標時間を設定できます。',
              style: TextStyle(fontSize: 13, color: context.pal.secondary),
            ),

            const SizedBox(height: 12),

            // ======================================================
            // 全て同じ時間を設定（カード全体を押せる）
            // ======================================================
            Material(
              color: context.pal.card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _selectTime(
                    currentMinutes: sameTimeMinutes,
                    onSelected: (value) {
                      setState(() {
                        sameTimeMinutes = value;
                        goalMinutes = List<int>.filled(7, value);
                      });
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.pal.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.pal.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '全て同じ時間を設定',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.pal.text,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'すべての曜日をまとめて設定',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.pal.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      _buildTimeValue(sameTimeMinutes),

                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: context.pal.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ======================================================
            // 曜日ごとの目標時間
            // ======================================================
            Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                '曜日ごとの目標時間',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.pal.text,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // カードの中にカードを入れない
            // 1つの一覧として表示（行全体を押せる）
            Container(
              decoration: BoxDecoration(
                color: context.pal.card,
                borderRadius: BorderRadius.circular(18),
              ),

              // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.pal.border),
              ),

              clipBehavior: Clip.antiAlias,

              child: Column(
                children: List.generate(7, (index) {
                  final isWeekend = index >= 5;
                  final dayColor = _dayColor(index);

                  return Column(
                    children: [
                      Material(
                        color: context.pal.card,
                        child: InkWell(
                          onTap: () {
                            _selectTime(
                              currentMinutes: goalMinutes[index],

                              onSelected: (value) {
                                setState(() {
                                  goalMinutes[index] = value;
                                });
                              },
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                              child: Row(
                                children: [
                                  // 曜日の頭文字の丸印
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dayColor.withValues(
                                        alpha: isWeekend ? 0.12 : 0.06,
                                      ),
                                    ),
                                    child: Text(
                                      weekdays[index].substring(0, 1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: dayColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      weekdays[index],
                                      style: TextStyle(
                                        color: dayColor,
                                        fontSize: 15,
                                        fontWeight: isWeekend
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),

                                  _buildTimeValue(goalMinutes[index]),

                                  const SizedBox(width: 2),

                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: context.pal.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (index < 6)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 58),
                          color: context.pal.divider,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // 下に固定：今週の合計と保存ボタン（いつでも押せる）
      // ============================================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.pal.card,
          border: Border(top: BorderSide(color: context.pal.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今週の目標合計',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.pal.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildTimeValue(weeklyTotal, numberSize: 20),
                  ],
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveGoals,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,

                        // 両端が丸いボタン
                        shape: const StadiumBorder(),
                      ),

                      child: const Text(
                        '保存する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
