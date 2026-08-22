import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_support_app/main.dart' as app;

class GoaltimeSettingScreen extends StatefulWidget {
  const GoaltimeSettingScreen({super.key});

  @override
  State<GoaltimeSettingScreen> createState() => _GoaltimeSettingScreenState();
}

class _GoaltimeSettingScreenState extends State<GoaltimeSettingScreen> {
  static const Color primaryBlue = Color(0xFF258EDB);

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
    final prefs = await SharedPreferences.getInstance();

    final loadedGoals = List<int>.generate(
      7,
      (index) => prefs.getInt('weekdayGoalMinutes_${index + 1}') ?? 0,
    );

    if (!mounted) return;

    setState(() {
      goalMinutes = loadedGoals;
    });
  }

  // ==============================================================
  // 時間表示
  // ==============================================================

  String _formatTime(int minutes) {
    if (minutes <= 0) {
      return '未設定';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours時間00分';
    }

    return '$hours時間${remainingMinutes.toString().padLeft(2, '0')}分';
  }

  // ==============================================================
  // 時間選択
  // ==============================================================

  Future<void> _selectTime({
    required int currentMinutes,
    required ValueChanged<int> onSelected,
  }) async {
    const options = <int>[
      30,
      60,
      90,
      120,
      150,
      180,
      210,
      240,
      270,
      300,
      330,
      360,
      420,
      480,
      540,
      600,
      720,
    ];

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                '目標時間を選択',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: options.length + 1,
                  itemBuilder: (context, index) {
                    // 未設定
                    if (index == 0) {
                      return ListTile(
                        title: const Text('未設定'),
                        trailing: currentMinutes == 0
                            ? const Icon(Icons.check, color: primaryBlue)
                            : null,
                        onTap: () {
                          Navigator.pop(context, 0);
                        },
                      );
                    }

                    final value = options[index - 1];

                    return ListTile(
                      title: Text(_formatTime(value)),
                      trailing: currentMinutes == value
                          ? const Icon(Icons.check, color: primaryBlue)
                          : null,
                      onTap: () {
                        Navigator.pop(context, value);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  // ==============================================================
  // 全曜日に同じ時間を設定
  // ==============================================================

  void _applySameTime() {
    setState(() {
      goalMinutes = List<int>.filled(7, sameTimeMinutes);
    });
  }

  // ==============================================================
  // 保存
  // ==============================================================

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < 7; i++) {
      await prefs.setInt('weekdayGoalMinutes_${i + 1}', goalMinutes[i]);
    }

    // 今日の目標時間も更新
    final todayMinutes = goalMinutes[DateTime.now().weekday - 1];

    app.dailyTargetHours.value = todayMinutes / 60.0;

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ==============================================================
  // UI
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final weeklyTotal = goalMinutes.fold<int>(0, (sum, value) => sum + value);

    return Scaffold(
      backgroundColor: Colors.white,

      // ============================================================
      // AppBar
      // ============================================================
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,

        title: const Text(
          '曜日ごとの目標設定',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      // ============================================================
      // Body
      // ============================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '曜日ごとに学習目標時間を設定できます。',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // 全て同じ時間を設定
            // ======================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCADFF2)),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: primaryBlue,
                    size: 24,
                  ),

                  const SizedBox(width: 9),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '全て同じ時間を設定',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          'すべての曜日を同じ目標時間にします。',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 時間選択
                  InkWell(
                    borderRadius: BorderRadius.circular(8),

                    onTap: () {
                      _selectTime(
                        currentMinutes: sameTimeMinutes,
                        onSelected: (value) {
                          setState(() {
                            sameTimeMinutes = value;
                          });
                        },
                      );
                    },

                    child: Container(
                      width: 105,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE1E5EA)),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Flexible(
                            child: Text(
                              _formatTime(sameTimeMinutes),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 7),

                  // 設定ボタン
                  SizedBox(
                    height: 42,

                    child: ElevatedButton(
                      onPressed: _applySameTime,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      child: const Text(
                        '設定',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ======================================================
            // 曜日ごとの目標時間
            // ======================================================
            const Text(
              '曜日ごとの目標時間',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 7),

            // カードの中にカードを入れない
            // 1つの一覧として表示
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5EA)),
              ),

              clipBehavior: Clip.antiAlias,

              child: Column(
                children: List.generate(7, (index) {
                  final isSaturday = index == 5;
                  final isSunday = index == 6;

                  return Column(
                    children: [
                      SizedBox(
                        height: 59,

                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),

                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  weekdays[index],

                                  style: TextStyle(
                                    color: isSunday
                                        ? const Color(0xFFE53935)
                                        : isSaturday
                                        ? primaryBlue
                                        : Colors.black87,

                                    fontSize: 14,

                                    fontWeight: isSaturday || isSunday
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),

                              InkWell(
                                borderRadius: BorderRadius.circular(8),

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

                                child: Container(
                                  width: 145,

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),

                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCFCFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE1E5EA),
                                    ),
                                  ),

                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatTime(goalMinutes[index]),

                                          textAlign: TextAlign.center,

                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),

                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (index < 6)
                        Container(height: 1, color: const Color(0xFFE1E5EA)),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // 今週の目標合計
            // ======================================================
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5EA)),
              ),

              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: const [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),

                      SizedBox(width: 6),

                      Text(
                        '今週の目標合計',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    weeklyTotal == 0 ? '未設定' : _formatTime(weeklyTotal),

                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // 保存ボタン
            // ======================================================
            SizedBox(
              height: 48,

              child: ElevatedButton(
                onPressed: _saveGoals,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                child: const Text(
                  '保存する',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),

                SizedBox(width: 5),

                Text(
                  '設定した目標時間はホームに反映されます。',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
