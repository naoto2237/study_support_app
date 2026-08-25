import 'record_myrecord_screen2.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    _checkDateChange();
    loadPeriodStudyTime();
    calculateAchievedDays();
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

  String formatPeriodStudyTime(int totalSeconds) {
    // 100時間以上
    if (totalSeconds >= 100 * 3600) {
      final tenthsOfHour = (totalSeconds * 10) ~/ 3600;

      final wholeHours = tenthsOfHour ~/ 10;
      final decimal = tenthsOfHour % 10;

      return "$wholeHours.$decimal時間";
    }

    // 1時間未満
    if (totalSeconds < 3600) {
      final minutes = totalSeconds ~/ 60;

      return "${minutes}分";
    }

    // 1時間以上100時間未満
    final wholeHours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return "${wholeHours}時間${minutes}分";
  }

  String _dateId(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
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
  int todayFirestoreSeconds = 0;
  int periodFirestoreSeconds = 0;

  int achievedDays = 0;

  // 今週の学習時間を読み込み中か
  bool isLoadingWeeklyTime = true;

  // ==============================================================
  // 学習時間
  // ==============================================================

  double get currentStudyHours {
    return todayStudySeconds.value / 3600.0;
  }

  double get periodStudyHours {
    return periodFirestoreSeconds / 3600.0;
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

    return (periodStudyHours / weeklyGoalHours * 100).round().clamp(0, 100);
  }

  Future<void> _checkDateChange() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDateString = prefs.getString('lastStudyDate');

    // 初回起動
    if (lastDateString == null) {
      await prefs.setString('lastStudyDate', _dateId(today));
      return;
    }

    final lastDate = DateTime.tryParse(lastDateString);

    if (lastDate == null) {
      await prefs.setString('lastStudyDate', _dateId(today));
      return;
    }

    // 日付が変わっていない
    if (!today.isAfter(lastDate)) {
      return;
    }

    // 前回確認した日から昨日までを確定
    DateTime date = lastDate;

    while (date.isBefore(today)) {
      await _saveDailyAchievement(date);

      date = date.add(const Duration(days: 1));
    }

    // 最後に確認した日を今日に更新
    await prefs.setString('lastStudyDate', _dateId(today));
  }

  Future<void> _saveDailyAchievement(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final dateId = _dateId(date);

    final studyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('studyRecords')
        .doc(dateId);

    final studyDoc = await studyRef.get();

    int studySeconds = 0;

    if (studyDoc.exists) {
      final data = studyDoc.data();

      studySeconds = (data?['studyTime'] as num?)?.toInt() ?? 0;

      // すでに確定済みなら何もしない
      if (data?['goalAchieved'] != null) {
        return;
      }
    }

    // ----------------------------------------------------------
    // その日の目標
    // ----------------------------------------------------------

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    if (userData == null) return;

    final goaltime = userData['goaltime'] as Map<String, dynamic>?;

    if (goaltime == null) return;

    const weekdayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final goalMinutes =
        (goaltime[weekdayKeys[date.weekday - 1]] as num?)?.toInt() ?? 0;

    final goalSeconds = goalMinutes * 60;

    final goalAchieved = goalMinutes > 0 && studySeconds >= goalSeconds;

    // ----------------------------------------------------------
    // その日の状態を確定保存
    // ----------------------------------------------------------

    await studyRef.set({
      'goalMinutes': goalMinutes,
      'goalAchieved': goalAchieved,
      'goalFinalized': true,
    }, SetOptions(merge: true));
  }

  // ==============================================================
  // 連続学習
  // ==============================================================

  Future<void> calculateAchievedDays() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          achievedDays = 0;
        });
      }
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;

    // ==============================================================
    // 今週
    // ==============================================================
    if (selectedPeriod == 0) {
      startDate = today.subtract(Duration(days: today.weekday - 1));
    }
    // ==============================================================
    // 今月
    // ==============================================================
    else if (selectedPeriod == 1) {
      startDate = DateTime(today.year, today.month, 1);
    }
    // ==============================================================
    // 今年
    // ==============================================================
    else {
      startDate = DateTime(today.year, 1, 1);
    }

    // ==============================================================
    // 日付一覧
    // ==============================================================

    final dates = <DateTime>[];

    for (
      DateTime date = startDate;
      !date.isAfter(today);
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }

    // ==============================================================
    // 達成状況を取得
    // ==============================================================

    final futures = dates.map((date) async {
      final dateId = _dateId(date);

      final studyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('studyRecords')
          .doc(dateId)
          .get();

      if (!studyDoc.exists) {
        return false;
      }

      final data = studyDoc.data();

      // 保存済みの達成結果だけを見る
      return data?['goalAchieved'] == true;
    });

    final results = await Future.wait(futures);

    final count = results.where((achieved) => achieved).length;

    if (!mounted) return;

    setState(() {
      achievedDays = count;
    });
  }

  Future<void> loadPeriodStudyTime() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          studyRecords.clear();
          periodFirestoreSeconds = 0;
          todayFirestoreSeconds = 0;
          isLoadingWeeklyTime = false;
        });
      }
      return;
    }

    final now = DateTime.now();

    DateTime startDate;
    DateTime endDate;

    // ==============================================================
    // 週
    // 選択されている週の7日間
    // ==============================================================
    if (selectedPeriod == 0) {
      startDate = DateTime(
        selectedWeekStart.year,
        selectedWeekStart.month,
        selectedWeekStart.day,
      );

      endDate = startDate.add(const Duration(days: 6));
    }
    // ==============================================================
    // 月
    // 今月の1日～今日
    // ==============================================================
    else if (selectedPeriod == 1) {
      startDate = DateTime(now.year, now.month, 1);

      endDate = DateTime(now.year, now.month, now.day);
    }
    // ==============================================================
    // 年
    // 今年の1月1日～今日
    // ==============================================================
    else {
      startDate = DateTime(now.year, 1, 1);

      endDate = DateTime(now.year, now.month, now.day);
    }

    int totalSeconds = 0;
    int savedTodaySeconds = 0;

    // 今回の期間のデータだけ入れ直す
    studyRecords.clear();

    // ==============================================================
    // 日付一覧を作成
    // ==============================================================
    final dates = <DateTime>[];

    for (
      DateTime date = startDate;
      !date.isAfter(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }

    // ==============================================================
    // Firestoreから各日の学習時間を取得
    // ==============================================================
    final futures = dates.map((date) async {
      final dateId = _dateId(date);

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("studyRecords")
          .doc(dateId)
          .get();

      int studySeconds = 0;

      if (doc.exists) {
        final data = doc.data();

        studySeconds = (data?["studyTime"] as num?)?.toInt() ?? 0;
      }

      return {"date": date, "studySeconds": studySeconds};
    });

    final results = await Future.wait(futures);

    // ==============================================================
    // 取得したデータを保存
    // ==============================================================
    for (final result in results) {
      final date = result["date"] as DateTime;
      final studySeconds = result["studySeconds"] as int;

      final key = "${date.year}/${date.month}/${date.day}";

      studyRecords[key] = studySeconds;

      totalSeconds += studySeconds;

      // 今日の保存済み時間
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        savedTodaySeconds = studySeconds;
      }
    }

    if (!mounted) return;

    setState(() {
      periodFirestoreSeconds = totalSeconds;
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

    final textColor = isDark ? Colors.white : Colors.black87;

    final secondaryColor = isDark ? Colors.white70 : Colors.black54;

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

                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "目標達成日数は、日付が変わると更新されます",
                      style: TextStyle(color: secondaryColor, fontSize: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                RecordMyRecordScreen2(
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  selectedPeriod: selectedPeriod,
                  selectedWeekStart: selectedWeekStart,
                  studyRecords: studyRecords,
                  currentStudyHours: currentStudyHours,
                  weeklyStudyHours: periodStudyHours,
                  weeklyGoalHours: weeklyGoalHours,
                  achievementRate: achievementRate,

                  onPeriodChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                      isLoadingWeeklyTime = true;
                    });

                    loadPeriodStudyTime();
                    calculateAchievedDays();
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

  String get _summaryDate {
    final now = DateTime.now();

    switch (selectedPeriod) {
      case 1:
        // 月
        return "${now.year}年${now.month}月";

      case 2:
        // 年
        return "${now.year}年";

      default:
        // 週
        final weekStart = selectedWeekStart;
        final weekEnd = selectedWeekStart.add(const Duration(days: 6));

        return "${formatDate(weekStart)} - ${formatDate(weekEnd)}";
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
                      _summaryDate,
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
                        value: formatPeriodStudyTime(
                          periodFirestoreSeconds -
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
                        value: achievedDays.toString(),
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
