import 'package:flutter/material.dart';
import 'comparison_screen2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        : const Color(0xFFF8F8FC);

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          children: [
            _buildConditionCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            ComparisonScreen2(
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  "比較する相手を選択",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              ListTile(
                title: const Text("全体のユーザー"),
                trailing: comparisonTarget == "全体のユーザー"
                    ? const Icon(Icons.check, color: Color(0xFF258EDB))
                    : null,
                onTap: () {
                  setState(() {
                    comparisonTarget = "全体のユーザー";
                  });

                  Navigator.pop(bottomSheetContext);
                },
              ),

              ListTile(
                title: const Text("特定のユーザー"),
                trailing: comparisonTarget == "特定のユーザー"
                    ? const Icon(Icons.check, color: Color(0xFF258EDB))
                    : null,
                onTap: () {
                  setState(() {
                    comparisonTarget = "特定のユーザー";
                  });

                  Navigator.pop(bottomSheetContext);
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

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _dropdown(
                  title: "比較する相手",
                  value: comparisonTarget,
                  textColor: textColor,
                  onTap: _showComparisonTargetSelector,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ユーザー数
          // 全体のユーザーを選択しているときだけ表示
          if (comparisonTarget == "全体のユーザー") ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF258EDB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xFF258EDB), size: 44),

                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "全体のユーザー数",
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        isUserCountLoading ? "読み込み中..." : "$userCount 人",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Icon(Icons.info_outline, color: Color(0xFF258EDB)),
                ],
              ),
            ),

            const SizedBox(height: 14),
          ],

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
                backgroundColor: const Color(0xFF258EDB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "比較する",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // カード
  // ============================================================

  Widget _card(Color color, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),

        const SizedBox(height: 7),

        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ),

                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
