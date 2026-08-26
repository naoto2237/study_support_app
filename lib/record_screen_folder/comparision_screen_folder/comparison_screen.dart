import 'package:flutter/material.dart';
import 'comparison_screen2.dart';

class ComparisonScreen extends StatefulWidget {
  final int totalSeconds;

  const ComparisonScreen({
    super.key,
    required this.totalSeconds,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String comparisonTarget = "全体のユーザー（平均）";

  // 週・月・年
  String selectedPeriod = "週";

  // 選択した期間
  String selectedDate = "8/16（日）- 8/22（土）";

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF8F8FC);

    final cardColor =
    isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor =
    isDark ? Colors.white : const Color(0xFF202124);

    final secondaryColor =
    isDark ? Colors.white70 : const Color(0xFF666666);

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          24,
        ),
        child: Column(
          children: [
            _buildConditionCard(
              cardColor,
              textColor,
              secondaryColor,
            ),

            const SizedBox(height: 14),

            ComparisonScreen2(
              totalSeconds: widget.totalSeconds,
              comparisonTarget: comparisonTarget,
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
  // 期間選択
  // ============================================================

  void _showPeriodAndDateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  "期間を選択",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 週
              ListTile(
                title: const Text("週"),
                subtitle: selectedPeriod == "週"
                    ? Text(selectedDate)
                    : null,
                trailing: selectedPeriod == "週"
                    ? const Icon(
                  Icons.check,
                  color: Color(0xFF258EDB),
                )
                    : null,
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  await _selectWeek();
                },
              ),

              // 月
              ListTile(
                title: const Text("月"),
                subtitle: selectedPeriod == "月"
                    ? Text(selectedDate)
                    : null,
                trailing: selectedPeriod == "月"
                    ? const Icon(
                  Icons.check,
                  color: Color(0xFF258EDB),
                )
                    : null,
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  await _selectMonth();
                },
              ),

              // 年
              ListTile(
                title: const Text("年"),
                subtitle: selectedPeriod == "年"
                    ? Text(selectedDate)
                    : null,
                trailing: selectedPeriod == "年"
                    ? const Icon(
                  Icons.check,
                  color: Color(0xFF258EDB),
                )
                    : null,
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  await _selectYear();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 週を選択
  // ============================================================

  Future<void> _selectWeek() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedPeriod = "週";
      selectedDate = _formatSelectedWeek(
        pickedDate,
      );
    });
  }

  // ============================================================
  // 月を選択
  // ============================================================

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedPeriod = "月";
      selectedDate =
      "${pickedDate.year}年${pickedDate.month}月";
    });
  }

  // ============================================================
  // 年を選択
  // ============================================================

  Future<void> _selectYear() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedPeriod = "年";
      selectedDate =
      "${pickedDate.year}年";
    });
  }

  // ============================================================
  // 週の表示
  // ============================================================

  String _formatSelectedWeek(DateTime date) {
    // 日曜日を週の開始日にする
    final daysFromSunday = date.weekday % 7;

    final startDate = date.subtract(
      Duration(days: daysFromSunday),
    );

    final endDate = startDate.add(
      const Duration(days: 6),
    );

    return "${startDate.year}/${startDate.month}/${startDate.day}"
        " ～ "
        "${endDate.year}/${endDate.month}/${endDate.day}";
  }

  // ============================================================
  // 比較対象の選択
  // ============================================================

  void _showComparisonTargetSelector() {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  "全体のユーザー（平均）",
                ),
                trailing:
                comparisonTarget ==
                    "全体のユーザー（平均）"
                    ? const Icon(
                  Icons.check,
                  color: Color(0xFF258EDB),
                )
                    : null,
                onTap: () {
                  setState(() {
                    comparisonTarget =
                    "全体のユーザー（平均）";
                  });

                  Navigator.pop(
                    bottomSheetContext,
                  );
                },
              ),

              ListTile(
                title: const Text(
                  "特定のユーザー",
                ),
                trailing:
                comparisonTarget ==
                    "特定のユーザー"
                    ? const Icon(
                  Icons.check,
                  color: Color(0xFF258EDB),
                )
                    : null,
                onTap: () {
                  setState(() {
                    comparisonTarget =
                    "特定のユーザー";
                  });

                  Navigator.pop(
                    bottomSheetContext,
                  );
                },
              ),
            ],
          ),
        );
      },
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
    return _card(
      cardColor,
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            "比較条件",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // 期間
          _dropdown(
            title: "期間",
            value:
            "$selectedPeriod：$selectedDate",
            textColor: textColor,
            onTap: _showPeriodAndDateSelector,
          ),

          const SizedBox(height: 12),

          // 比較する相手
          _dropdown(
            title: "比較する相手",
            value: comparisonTarget,
            textColor: textColor,
            onTap: _showComparisonTargetSelector,
          ),

          const SizedBox(height: 16),

          // ユーザー数
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF258EDB),
              ),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.groups,
                  color: Color(0xFF258EDB),
                  size: 44,
                ),

                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "全体のユーザー数",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "12,345 人",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Icon(
                  Icons.info_outline,
                  color: secondaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // カード
  // ============================================================

  Widget _card(
      Color color,
      Widget child,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // ドロップダウン風UI
  // ============================================================

  Widget _dropdown({
    required String title,
    required String value,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 7),

        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                const Color(0xFFE5E7EB),
              ),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}