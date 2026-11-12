// ======================================================================
// 【部品】比較結果（自分と相手の学習時間、週／月／年）
//
// 主なクラス: ComparisonResultSection
// ・その下に比較グラフ（comparison_chart_section.dart）を表示
// ・旧ファイル名: comparison_screen2.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/record/comparison/comparison_chart_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/theme/app_colors.dart';

class ComparisonResultSection extends StatefulWidget {
  final int totalSeconds;
  final String comparisonTarget;
  final ValueChanged<String> onComparisonTargetChanged;

  // 比較条件
  final bool isCompared;

  const ComparisonResultSection({
    super.key,
    required this.totalSeconds,
    required this.comparisonTarget,
    required this.onComparisonTargetChanged,
    required this.isCompared,
  });

  @override
  State<ComparisonResultSection> createState() =>
      _ComparisonResultSectionState();
}

class _ComparisonResultSectionState extends State<ComparisonResultSection> {
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

      return "$minutes分";
    }

    // 1時間以上100時間未満
    final wholeHours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return "$wholeHours時間$minutes分";
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
        ComparisonChartSection(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // 見出しと期間
          // ------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  "学習時間の比較",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _selectedDateText(),
                style: TextStyle(color: secondaryColor, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 週・月・年の切りかえ（グラフと同じ形）
          _buildPeriodSelector(textColor, isDark),

          const SizedBox(height: 16),

          if (!widget.isCompared)
            _buildNotCompared(secondaryColor, isDark)
          else if (widget.comparisonTarget == "全体のユーザー")
            _buildAllUsersComparison(textColor, secondaryColor, isDark)
          else
            _buildSpecificUserComparison(textColor, secondaryColor),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(Color textColor, bool isDark) {
    const titles = ["週", "月", "年"];

    return Container(
      height: 33,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(titles.length, (index) {
          final selected = selectedPeriod == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedPeriod == index) return;

                setState(() {
                  selectedPeriod = index;
                });

                _loadMyStudyHours();
                _loadAverageStudyHours();
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  titles[index],
                  style: TextStyle(
                    color: selected ? Colors.white : textColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==============================================================
  // 比較前
  // ==============================================================

  Widget _buildNotCompared(Color secondaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primarySoft,
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "上の「比較する」を押すと、ここに結果が出ます",
              style: TextStyle(color: secondaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 全体のユーザーとの比較
  // ==============================================================

  Widget _buildAllUsersComparison(
    Color textColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final isLoading = isLoadingMyStudyTime || isLoadingAverage;

    final mySeconds = myStudySeconds ?? 0;
    final averageSeconds = ((averageStudyHours ?? 0) * 3600).round();

    final difference = mySeconds - averageSeconds;

    // 横の棒の長さの基準（長いほうをいっぱいにする）
    final maxSeconds = mySeconds > averageSeconds ? mySeconds : averageSeconds;

    // 平均より多いときは青、少ないときは赤
    final differenceColor = difference >= 0
        ? AppColors.primary
        : const Color(0xFFE5534B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // あなた／全体平均の横の棒
        // ------------------------------------------------------
        _barRow(
          title: "あなた",
          value: isLoading ? "--" : formatStudyTime(mySeconds),
          ratio: maxSeconds > 0 ? mySeconds / maxSeconds : 0,
          barColor: AppColors.primary,
          valueColor: AppColors.primary,
          secondaryColor: secondaryColor,
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        _barRow(
          title: "全体平均",
          value: isLoading ? "--" : formatStudyTime(averageSeconds),
          ratio: maxSeconds > 0 ? averageSeconds / maxSeconds : 0,
          barColor: isDark ? Colors.white38 : const Color(0xFFBDBDBD),
          valueColor: textColor,
          secondaryColor: secondaryColor,
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // ------------------------------------------------------
        // 差（「平均より ○分 多い／少ない」）
        // ------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isLoading
                ? (isDark ? Colors.white10 : AppColors.background)
                : differenceColor.withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? Text(
                  "読み込み中…",
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      difference > 0
                          ? Icons.trending_up_rounded
                          : difference < 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                      color: differenceColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "平均より",
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    if (difference != 0) ...[
                      _buildStudyTimeRichText(
                        formatStudyTime(difference.abs()),
                        "",
                        differenceColor,
                        numberSize: 20,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      difference > 0
                          ? "多い"
                          : difference < 0
                          ? "少ない"
                          : "同じ",
                      style: TextStyle(
                        color: differenceColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // 横の棒1本（左に名前、右に時間、下に長さの棒）
  Widget _barRow({
    required String title,
    required String value,
    required double ratio,
    required Color barColor,
    required Color valueColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    // 少しでも勉強していれば、短くても見えるようにする
    final shownRatio = ratio > 0 && ratio < 0.03 ? 0.03 : ratio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: secondaryColor, fontSize: 12.5),
              ),
            ),
            _buildStudyTimeRichText(value, "", valueColor, numberSize: 20),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: isDark ? Colors.white10 : AppColors.background,
              ),
              FractionallySizedBox(
                widthFactor: shownRatio.clamp(0.0, 1.0),
                child: Container(height: 8, color: barColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // 特定ユーザーとの比較（相手を選ぶ機能は準備中）
  // ==============================================================

  Widget _buildSpecificUserComparison(Color textColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                "あなた",
                style: TextStyle(color: secondaryColor, fontSize: 12.5),
              ),
            ),
            _buildStudyTimeRichText(
              isLoadingMyStudyTime
                  ? "--"
                  : formatStudyTime(myStudySeconds ?? 0),
              "",
              AppColors.primary,
              numberSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "比較する相手を選ぶ機能は準備中です",
          style: TextStyle(color: secondaryColor, fontSize: 12),
        ),
      ],
    );
  }

  // ==============================================================
  // 時間の文字（数字は Roboto で大きく、単位は小さく）
  // ==============================================================

  Widget _buildStudyTimeRichText(
    String value,
    String unit,
    Color color, {
    double numberSize = 24,
  }) {
    // 読み込み中
    if (value == "--") {
      return Text(
        "--",
        style: GoogleFonts.roboto(
          color: color,
          fontSize: numberSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // 例: 12時間34分 / 45分 / 123.4時間
    final regex = RegExp(r'(\d+(?:\.\d+)?)(時間|分)');

    final spans = <TextSpan>[];

    for (final match in regex.allMatches(value)) {
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.roboto(
            color: color,
            fontSize: numberSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: color,
            fontSize: numberSize * 0.56,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (unit.isNotEmpty) {
      spans.add(
        TextSpan(
          text: " $unit",
          style: TextStyle(
            color: color,
            fontSize: numberSize * 0.56,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
