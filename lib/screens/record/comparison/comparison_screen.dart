// ======================================================================
// 【タブ】学習記録の「他の人と比較」タブ
//
// 主なクラス: ComparisonScreen
// ・比較する相手（全体のユーザー／特定のユーザー）を切りかえボタンで選ぶ
// ・その下に比較結果（comparison_result_section.dart）を表示
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/record/comparison/comparison_result_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/theme/app_colors.dart';

class ComparisonScreen extends StatefulWidget {
  final int totalSeconds;

  const ComparisonScreen({super.key, required this.totalSeconds});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String comparisonTarget = "全体のユーザー";

  // ユーザー数
  int userCount = 0;
  bool isUserCountLoading = true;

  String selectedPeriod = "週";
  String selectedDate = "";
  bool isCompared = false;

  @override
  void initState() {
    super.initState();

    _loadUserCount();
  }

  Future<void> _loadUserCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .count()
          .get();

      if (!mounted) return;

      setState(() {
        userCount = snapshot.count ?? 0;
        isUserCountLoading = false;
      });
    } catch (e) {
      debugPrint("ユーザー数の取得に失敗しました: $e");

      if (!mounted) return;

      setState(() {
        isUserCountLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : AppColors.background;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
        child: Column(
          children: [
            _buildConditionCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            ComparisonResultSection(
              totalSeconds: widget.totalSeconds,
              comparisonTarget: comparisonTarget,
              isCompared: isCompared,
              onComparisonTargetChanged: (value) {
                setState(() {
                  comparisonTarget = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 比較条件カード
  // ============================================================

  Widget _buildConditionCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _card(
      cardColor,
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "比較条件",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Text("比較する相手", style: TextStyle(color: secondaryColor, fontSize: 12)),

          const SizedBox(height: 6),

          // 相手の切りかえ（グラフの「週・月・年」と同じ形）
          _segmented(
            options: const ["全体のユーザー", "特定のユーザー"],
            selected: comparisonTarget == "全体のユーザー" ? 0 : 1,
            textColor: textColor,
            isDark: isDark,
            onSelected: (index) {
              setState(() {
                comparisonTarget = index == 0 ? "全体のユーザー" : "特定のユーザー";
              });
            },
          ),

          const SizedBox(height: 14),

          // 相手についての説明（うすい青の面）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    comparisonTarget == "全体のユーザー"
                        ? Icons.groups_rounded
                        : Icons.person_search_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: comparisonTarget == "全体のユーザー"
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "全体のユーザー数",
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUserCountLoading ? "読み込み中…" : "$userCount人",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "勉強しなかった人も、0時間として平均に入れます",
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "比較する相手を選ぶ機能は準備中です。\nいまは自分の記録だけを表示します",
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 比較するボタン
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isCompared = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isCompared ? "もう一度比較する" : "比較する",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 切りかえボタン（グラフの「週・月・年」と同じ形）
  // ============================================================

  Widget _segmented({
    required List<String> options,
    required int selected,
    required Color textColor,
    required bool isDark,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontSize: 13.5,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // カード
  // ============================================================

  Widget _card(Color color, bool isDark, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
      ),
      child: child,
    );
  }
}
