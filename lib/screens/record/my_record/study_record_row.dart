// ======================================================================
// 【部品】学習記録の1行（日付・その日の学習時間・長さのバー）
//
// 主なクラス: StudyRecordRow
// 表示される場所: 最近の学習記録（recent_records_section.dart）
//               学習記録の一覧（all_study_records_screen.dart）
// ・左：日にちと曜日（土は青、日は赤。グラフの日付と同じ色）
// ・まん中：「11月12日」と、学習時間の長さを表すバー（今日は「今日」の印つき）
// ・右：学習時間
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';

class StudyRecordRow extends StatelessWidget {
  // "2026-11-12" の形の日付
  final String dateId;

  // その日の学習時間（秒）
  final int seconds;

  // バーの長さの基準にする秒（いっしょに並ぶ行の中でいちばん長い時間）
  final int maxSeconds;

  final Color textColor;
  final Color secondaryColor;

  // 下に区切り線を出すか
  final bool showDivider;

  const StudyRecordRow({
    super.key,
    required this.dateId,
    required this.seconds,
    required this.maxSeconds,
    required this.textColor,
    required this.secondaryColor,
    this.showDivider = true,
  });

  static const _weekdays = ["月", "火", "水", "木", "金", "土", "日"];

  // 土日の色（グラフの日付の色と合わせる）
  static const _saturdayColor = AppColors.primary;
  static const _sundayColor = Color(0xFFE53935);

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _weekdayColor(DateTime date) {
    if (date.weekday == DateTime.saturday) return _saturdayColor;
    if (date.weekday == DateTime.sunday) return _sundayColor;
    return secondaryColor;
  }

  static String formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "$hours時間$minutes分";
    }

    if (minutes > 0) {
      return "$minutes分$remainingSeconds秒";
    }

    return "$remainingSeconds秒";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = DateTime.parse(dateId);
    final isToday = _isToday(date);

    // バーの長さ（0～1）。少しでも勉強した日は、短くても見えるようにする
    double ratio = maxSeconds > 0 ? seconds / maxSeconds : 0;
    if (seconds > 0 && ratio < 0.04) ratio = 0.04;

    final trackColor = isDark ? Colors.white12 : AppColors.primaryTrack;
    final dividerColor = isDark ? Colors.white12 : AppColors.divider;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor)),
            )
          : null,
      child: Row(
        children: [
          // ------------------------------------------------------
          // 左：日にちと曜日
          // ------------------------------------------------------
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : AppColors.primarySoft),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${date.day}",
                  style: TextStyle(
                    color: isToday ? Colors.white : textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  _weekdays[date.weekday - 1],
                  style: TextStyle(
                    color: isToday ? Colors.white : _weekdayColor(date),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ------------------------------------------------------
          // まん中：月日と長さのバー
          // ------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${date.month}月${date.day}日",
                      style: TextStyle(color: secondaryColor, fontSize: 12),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "今日",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 7),

                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 6, color: trackColor),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primary,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ------------------------------------------------------
          // 右：学習時間
          // ------------------------------------------------------
          SizedBox(
            width: 78,
            child: Text(
              formatStudyTime(seconds),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: seconds > 0 ? textColor : secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
