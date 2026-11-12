// ======================================================================
// 【部品】「曜日ごとの目標を設定」ボタン（ホーム画面の中に表示）
//
// 主なクラス: WeekdayGoalButton
// ・押すと曜日ごとの目標設定画面（goal_time_setting_screen.dart）を開く
// ・旧ファイル名: home_screen2.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/home/goal_time_setting_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

class WeekdayGoalButton extends StatelessWidget {
  const WeekdayGoalButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primarySoft;
    final fg = isDark ? const Color(0xFF8CC4F2) : AppColors.primaryDeep;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalTimeSettingScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                // アイコン（白い丸の中）
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: fg,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '曜日ごとの目標を設定',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '曜日ごとに目標時間をカスタマイズできます',
                        style: TextStyle(
                          fontSize: 12,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right_rounded, color: fg, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
