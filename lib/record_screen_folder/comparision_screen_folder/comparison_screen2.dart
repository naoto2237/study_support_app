import 'package:flutter/material.dart';
import 'comparison_screen3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparisonScreen2 extends StatefulWidget {
  final int totalSeconds;
  final String comparisonTarget;
  final ValueChanged<String> onComparisonTargetChanged;

  // 比較条件
  final bool isCompared;

  const ComparisonScreen2({
    super.key,
    required this.totalSeconds,
    required this.comparisonTarget,
    required this.onComparisonTargetChanged,
    required this.isCompared,
  });

  @override
  State<ComparisonScreen2> createState() => _ComparisonScreen2State();
}

class _ComparisonScreen2State extends State<ComparisonScreen2> {
  String formatStudyTime(int totalSeconds) {
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

  // =============================================================
  // 自分の学習時間
  // =============================================================

  int? myStudySeconds;
  bool isLoadingMyStudyTime = false;

  // 0:週、1:月、2:年
  int selectedPeriod = 0;

  // 全ユーザーの平均学習時間
  double? averageStudyHours;

  bool isLoadingAverage = false;

  // ==============================================================
  // 日付表示
  // ==============================================================

  String _selectedDateText() {
    final now = DateTime.now();

    // 週（月曜日～日曜日）
    if (selectedPeriod == 0) {
      final monday = now.subtract(Duration(days: now.weekday - 1));

      final sunday = monday.add(const Duration(days: 6));

      return "${monday.month}/${monday.day}"
          " - "
          "${sunday.month}/${sunday.day}";
    }

    // 月
    if (selectedPeriod == 1) {
      return "${now.year}年${now.month}月";
    }

    // 年
    return "${now.year}年";
  }

  // ==============================================================
  // 期間タイトル
  // ==============================================================

  String _periodText() {
    switch (selectedPeriod) {
      case 1:
        return "月";

      case 2:
        return "年";

      default:
        return "週";
    }
  }

  // ==============================================================
  // 初期化
  // ==============================================================
  @override
  void initState() {
    super.initState();

    _loadMyStudyHours();
    _loadAverageStudyHours();
  }

  // =============================================================
  // 自分の学習時間を取得
  // =============================================================

  Future<void> _loadMyStudyHours() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("ログイン中のユーザーがいません");
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoadingMyStudyTime = true;
    });

    try {
      final now = DateTime.now();

      late DateTime startDate;
      late DateTime endDate;

      // =========================================================
      // 週（月曜日～日曜日）
      // =========================================================

      if (selectedPeriod == 0) {
        final daysFromMonday = now.weekday - 1;

        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysFromMonday));

        endDate = startDate.add(const Duration(days: 7));
      }
      // =========================================================
      // 月
      // =========================================================
      else if (selectedPeriod == 1) {
        startDate = DateTime(now.year, now.month, 1);

        endDate = DateTime(now.year, now.month + 1, 1);
      }
      // =========================================================
      // 年
      // =========================================================
      else {
        startDate = DateTime(now.year, 1, 1);

        endDate = DateTime(now.year + 1, 1, 1);
      }

      // =========================================================
      // 自分の学習記録を取得
      // =========================================================

      final studySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("studyRecords")
          .get();

      int totalSeconds = 0;

      for (final recordDoc in studySnapshot.docs) {
        final date = DateTime.tryParse(recordDoc.id);

        if (date == null) {
          continue;
        }

        final recordDate = DateTime(date.year, date.month, date.day);

        // 選択した期間内だけ集計
        if (!recordDate.isBefore(startDate) && recordDate.isBefore(endDate)) {
          final data = recordDoc.data();

          totalSeconds += (data["studyTime"] as num?)?.toInt() ?? 0;
        }
      }

      if (!mounted) return;

      setState(() {
        myStudySeconds = totalSeconds;
        isLoadingMyStudyTime = false;
      });
    } catch (e) {
      debugPrint("自分の学習時間の取得に失敗: $e");

      if (!mounted) return;

      setState(() {
        myStudySeconds = null;
        isLoadingMyStudyTime = false;
      });
    }
  }

  // ==============================================================
  // 全ユーザーの平均学習時間を取得
  // ==============================================================

  Future<void> _loadAverageStudyHours() async {
    if (!mounted) return;

    setState(() {
      isLoadingAverage = true;
    });

    try {
      final now = DateTime.now();

      late DateTime startDate;
      late DateTime endDate;

      // ==========================================================
      // 週（月曜日～日曜日）
      // ==========================================================

      if (selectedPeriod == 0) {
        final daysFromMonday = now.weekday - 1;

        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysFromMonday));

        endDate = startDate.add(const Duration(days: 7));
      }
      // ==========================================================
      // 月
      // ==========================================================
      else if (selectedPeriod == 1) {
        startDate = DateTime(now.year, now.month, 1);

        endDate = DateTime(now.year, now.month + 1, 1);
      }
      // ==========================================================
      // 年
      // ==========================================================
      else {
        startDate = DateTime(now.year, 1, 1);

        endDate = DateTime(now.year + 1, 1, 1);
      }

      // ==========================================================
      // 全ユーザー取得
      // ==========================================================

      final usersSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();

      if (usersSnapshot.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          averageStudyHours = 0;
          isLoadingAverage = false;
        });

        return;
      }

      double totalAllUsersHours = 0;
      int userCount = 0;

      // ==========================================================
      // ユーザーごとに学習時間を集計
      // ==========================================================

      for (final userDoc in usersSnapshot.docs) {
        final studySnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userDoc.id)
            .collection("studyRecords")
            .get();

        int userTotalSeconds = 0;

        for (final recordDoc in studySnapshot.docs) {
          final date = DateTime.tryParse(recordDoc.id);

          if (date == null) {
            continue;
          }

          final recordDate = DateTime(date.year, date.month, date.day);

          if (!recordDate.isBefore(startDate) && recordDate.isBefore(endDate)) {
            final data = recordDoc.data();

            userTotalSeconds += (data["studyTime"] as num?)?.toInt() ?? 0;
          }
        }

        totalAllUsersHours += userTotalSeconds / 3600.0;

        // 学習時間0時間のユーザーも平均に含める
        userCount++;
      }

      // ==========================================================
      // 全ユーザー平均
      // ==========================================================

      final average = userCount == 0 ? 0.0 : totalAllUsersHours / userCount;

      if (!mounted) return;

      setState(() {
        averageStudyHours = average;
        isLoadingAverage = false;
      });
    } catch (e) {
      debugPrint("全ユーザー平均の取得に失敗: $e");

      if (!mounted) return;

      setState(() {
        averageStudyHours = null;
        isLoadingAverage = false;
      });
    }
  }

  // ==============================================================
  // build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    return Column(
      children: [
        // ==========================================================
        // 学習時間の比較
        // ==========================================================
        _buildComparisonTimeCard(cardColor, textColor),

        const SizedBox(height: 14),

        // ==========================================================
        // グラフ
        // ==========================================================
        ComparisonScreen3(
          totalSeconds: widget.totalSeconds,
          comparisonTarget: widget.comparisonTarget,
        ),
      ],
    );
  }

  // ==============================================================
  // 学習時間比較カード
  // ==============================================================

  Widget _buildComparisonTimeCard(Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // 上部
          // paddingあり
          // ========================================================
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ------------------------------------------------
                // 期間選択
                // ------------------------------------------------
                PopupMenuButton<int>(
                  color: Colors.white,
                  offset: const Offset(0, 8),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    setState(() {
                      selectedPeriod = value;
                    });

                    _loadMyStudyHours();
                    _loadAverageStudyHours();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(
                            selectedPeriod == 0
                                ? Icons.check
                                : Icons.circle_outlined,
                            size: 18,
                            color: selectedPeriod == 0
                                ? const Color(0xFF258EDB)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          const Text("週"),
                        ],
                      ),
                    ),

                    PopupMenuItem<int>(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(
                            selectedPeriod == 1
                                ? Icons.check
                                : Icons.circle_outlined,
                            size: 18,
                            color: selectedPeriod == 1
                                ? const Color(0xFF258EDB)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          const Text("月"),
                        ],
                      ),
                    ),

                    PopupMenuItem<int>(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(
                            selectedPeriod == 2
                                ? Icons.check
                                : Icons.circle_outlined,
                            size: 18,
                            color: selectedPeriod == 2
                                ? const Color(0xFF258EDB)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          const Text("年"),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "学習時間の比較 "
                        "(${_periodText()})",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 3),

                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 19,
                      ),
                    ],
                  ),
                ),

                // ------------------------------------------------
                // 日付
                // ------------------------------------------------
                Text(
                  _selectedDateText(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // ========================================================
          // 下部
          // paddingなし
          // ========================================================
          if (!widget.isCompared) _buildNotCompared(textColor),

          if (widget.isCompared && widget.comparisonTarget == "全体のユーザー")
            _buildAllUsersComparison(textColor),

          if (widget.isCompared && widget.comparisonTarget == "特定のユーザー")
            _buildSpecificUserComparison(textColor),
        ],
      ),
    );
  }

  // ==============================================================
  // 比較前
  // ==============================================================

  Widget _buildNotCompared(Color textColor) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 18),
          child: Center(
            child: Text(
              "「比較する」を押してください",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 全体のユーザーとの比較
  // ==============================================================

  Widget _buildAllUsersComparison(Color textColor) {
    final averageHours = averageStudyHours ?? 0.0;

    final myHours = (myStudySeconds ?? 0) / 3600.0;

    final difference = myHours - averageHours;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Stack(
        children: [
          // ========================================================
          // 3等分
          // ========================================================
          Row(
            children: [
              Expanded(
                child: _comparisonValue(
                  "自分の学習時間",
                  isLoadingMyStudyTime
                      ? "--"
                      : formatStudyTime(myStudySeconds ?? 0),
                  "",
                  const Color(0xFF258EDB),
                ),
              ),

              Expanded(
                child: _comparisonValue(
                  "全体平均",
                  isLoadingAverage
                      ? "--"
                      : formatStudyTime((averageHours * 3600).round()),
                  "",
                  textColor,
                ),
              ),

              Expanded(
                child: _comparisonValue(
                  "差分",
                  (isLoadingMyStudyTime || isLoadingAverage)
                      ? "--"
                      : "${difference > 0
                                ? '+'
                                : difference < 0
                                ? '-'
                                : ''}"
                            "${formatStudyTime((difference.abs() * 3600).round())}",
                  "",
                  const Color(0xFFE52B72),
                ),
              ),
            ],
          ),

          // ========================================================
          // 縦線
          // ========================================================
          Positioned.fill(
            child: IgnorePointer(
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),

                  Container(width: 1, height: 55, color: Colors.grey.shade300),

                  const Expanded(child: SizedBox()),

                  Container(width: 1, height: 55, color: Colors.grey.shade300),

                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 特定ユーザーとの比較
  // ==============================================================

  Widget _buildSpecificUserComparison(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: _comparisonValue(
            "自分の学習時間",
            isLoadingMyStudyTime ? "--" : formatStudyTime(myStudySeconds ?? 0),
            "",
            const Color(0xFF258EDB),
          ),
        ),

        Container(width: 1, height: 65, color: Colors.grey.shade300),

        Expanded(child: _comparisonValue("比較相手", "--", "時間", textColor)),
      ],
    );
  }

  // ==============================================================
  // 数値表示
  // ==============================================================

  Widget _comparisonValue(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildStudyTimeRichText(value, unit, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeRichText(String value, String unit, Color color) {
    // 読み込み中
    if (value == "--") {
      return Text(
        "--",
        style: GoogleFonts.roboto(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // 時間・分が含まれていない普通の値の場合
    if (!value.contains("時間") && !value.contains("分")) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.roboto(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              TextSpan(
                text: " $unit",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    }

    // 例:
    // 12時間34分
    // 45分
    // +3時間20分
    // -1時間30分
    // 123.4時間
    final regex = RegExp(r'([+-]?\d+(?:\.\d+)?)(時間|分)');

    final spans = <TextSpan>[];

    for (final match in regex.allMatches(value)) {
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.roboto(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: match.group(2),
          style: GoogleFonts.roboto(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
