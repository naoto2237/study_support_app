import 'record_myrecord_screen2.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordMyRecordScreen extends StatefulWidget {
  const RecordMyRecordScreen({super.key});

  Future<int> getThisWeekStudySeconds() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 0;
    }

    final now = DateTime.now();

    // 月曜日を取得
    final monday = now.subtract(Duration(days: now.weekday - 1));

    int totalSeconds = 0;

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));

      final dateId =
          "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("studyRecords")
          .doc(dateId)
          .get();

      if (doc.exists) {
        final data = doc.data();

        totalSeconds += (data?["studyTime"] as num?)?.toInt() ?? 0;
      }
    }

    return totalSeconds;
  }

  @override
  State<RecordMyRecordScreen> createState() => _RecordMyRecordScreenState();
}

class _RecordMyRecordScreenState extends State<RecordMyRecordScreen> {
  @override
  void initState() {
    super.initState();

    loadWeeklyStudyTime();
  }

  String formatStudyTime(int totalSeconds) {
    // 100時間以上
    if (totalSeconds >= 100 * 3600) {
      // 小数第1位まで、四捨五入せず切り捨て
      final tenthsOfHour = (totalSeconds * 10) ~/ 3600;

      final wholeHours = tenthsOfHour ~/ 10;
      final decimal = tenthsOfHour % 10;

      return "$wholeHours.$decimal時間";
    }

    // 1時間未満
    if (totalSeconds < 3600) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;

      return "${minutes}分${seconds}秒";
    }

    // 1時間以上100時間未満
    final wholeHours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return "${wholeHours}時間${minutes}分";
  }

  // ==============================================================
  // 週 / 月 / 年
  // ==============================================================

  int selectedPeriod = 0;

  // ==============================================================
  // 表示する週
  // ==============================================================

  DateTime selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  // ==============================================================
  // 学習記録
  // ==============================================================
  final Map<String, int> studyRecords = {};

  // 今週のFirestore上の学習時間
  int weeklyFirestoreSeconds = 0;
  int todayFirestoreSeconds = 0;

  // 今週の学習時間を読み込み中か
  bool isLoadingWeeklyTime = true;

  // ==============================================================
  // 学習時間
  // ==============================================================

  double get currentStudyHours {
    return todayStudySeconds.value / 3600.0;
  }

  double get weeklyStudyHours {
    return weeklyFirestoreSeconds / 3600.0;
  }

  // ==============================================================
  // 目標時間
  // ※今は仮値
  // ==============================================================
  double get weeklyGoalHours {
    return 12.3;
  }

  double get averageDailyGoal {
    return weeklyGoalHours / 7;
  }

  int get achievementRate {
    if (weeklyGoalHours <= 0) {
      return 0;
    }

    return (weeklyStudyHours / weeklyGoalHours * 100).round().clamp(0, 100);
  }

  // ==============================================================
  // 連続学習
  // ==============================================================

  int calculateStreak() {
    if (todayStudySeconds.value > 0) {
      return 1;
    }

    return 0;
  }

  Future<void> loadWeeklyStudyTime() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          weeklyFirestoreSeconds = 0;
          isLoadingWeeklyTime = false;
        });
      }
      return;
    }

    final now = DateTime.now();

    // 今週の月曜日
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    int totalSeconds = 0;
    int savedTodaySeconds = 0;

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));

      final dateId =
          "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("studyRecords")
          .doc(dateId)
          .get();

      if (doc.exists) {
        final data = doc.data();

        final studySeconds = (data?["studyTime"] as num?)?.toInt() ?? 0;

        totalSeconds += studySeconds;

        // 今日の保存済み時間
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          savedTodaySeconds = studySeconds;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      weeklyFirestoreSeconds = totalSeconds;
      todayFirestoreSeconds = savedTodaySeconds;
      isLoadingWeeklyTime = false;
    });
  }

  // ==============================================================
  // 日付
  // ==============================================================

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}";
  }

  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF8F8FC);

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return ValueListenableBuilder<int>(
      valueListenable: todayStudySeconds,
      builder: (context, seconds, child) {
        return Container(
          color: backgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              children: [
                _buildSummaryCard(cardColor, textColor, secondaryColor),

                const SizedBox(height: 14),

                RecordMyRecordScreen2(
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  selectedPeriod: selectedPeriod,
                  selectedWeekStart: selectedWeekStart,
                  studyRecords: studyRecords,
                  currentStudyHours: currentStudyHours,
                  weeklyStudyHours: weeklyStudyHours,
                  weeklyGoalHours: weeklyGoalHours,
                  achievementRate: achievementRate,

                  onPeriodChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                    });
                  },

                  onWeekChanged: (value) {
                    setState(() {
                      selectedWeekStart = value;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // 今週のサマリー
  // ==============================================================
  String get _summaryTitle {
    switch (selectedPeriod) {
      case 1:
        return "今月のサマリー";
      case 2:
        return "今年のサマリー";
      default:
        return "今週のサマリー";
    }
  }

  Widget _buildSummaryCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // ======================================================
          // 上のサマリー部分
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _summaryTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "${formatDate(selectedWeekStart)} - "
                      "${formatDate(selectedWeekStart.add(const Duration(days: 6)))}",
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ======================================================
          // 下の3領域
          // 左右の余白なし
          // ======================================================
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryItem(
                        title: "今日の学習時間",
                        value: formatStudyTime(todayStudySeconds.value),
                        unit: "",
                        color: textColor,
                        bottomText: '',
                      ),
                    ),

                    Expanded(
                      child: _summaryItem(
                        title: selectedPeriod == 0
                            ? "今週の学習時間"
                            : selectedPeriod == 1
                            ? "今月の学習時間"
                            : "今年の学習時間",
                        value: formatStudyTime(
                          weeklyFirestoreSeconds -
                              todayFirestoreSeconds +
                              todayStudySeconds.value,
                        ),
                        unit: "",
                        color: textColor,
                        bottomText: '',
                      ),
                    ),

                    Expanded(
                      child: _summaryItem(
                        title: "目標達成日数",
                        value: calculateStreak().toString(),
                        unit: "日",
                        color: textColor,
                        bottomText: '',
                      ),
                    ),
                  ],
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        const Expanded(child: SizedBox()),

                        Container(
                          width: 1,
                          height: 45,
                          color: Colors.grey.shade300,
                        ),

                        const Expanded(child: SizedBox()),

                        Container(
                          width: 1,
                          height: 45,
                          color: Colors.grey.shade300,
                        ),

                        const Expanded(child: SizedBox()),
                      ],
                    ),
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
  // 共通カード
  // ==============================================================

  Widget _card(Color color, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  // ==============================================================
  // サマリー項目
  // ==============================================================

  Widget _summaryItem({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required String bottomText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 11)),

        const SizedBox(height: 9),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              ..._buildTimeSpans(value, color),

              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),

        if (bottomText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(bottomText, style: const TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  // ==============================================================
  // 数字だけRoboto
  // ==============================================================

  List<TextSpan> _buildTimeSpans(String value, Color color) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\d+(?:\.\d+)?)(時間|分|秒)');
    final matches = regex.allMatches(value);

    // 「1時間30分」など
    if (matches.isNotEmpty) {
      for (final match in matches) {
        final number = match.group(1)!;
        final unit = match.group(2)!;

        // 数字 → 25px
        spans.add(
          TextSpan(
            text: number,
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        // 単位 → 14px
        spans.add(
          TextSpan(
            text: unit,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      return spans;
    }

    // 「1」のように数字だけ
    return [
      TextSpan(
        text: value,
        style: GoogleFonts.roboto(
          color: color,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  // ==============================================================
  // 区切り線
  // ==============================================================

  Widget _divider() {
    return Container(width: 1, height: 45, color: Colors.grey.shade300);
  }
}
