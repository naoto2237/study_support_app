import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ComparisonScreen extends StatefulWidget {
  final int totalSeconds;

  const ComparisonScreen({super.key, required this.totalSeconds});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  // ==============================================================
  // 週 / 月 / 年
  // ==============================================================

  int selectedPeriod = 0;

  // ==============================================================
  // 比較相手
  // ==============================================================

  String comparisonTarget = "全体のユーザー（平均）";

  // ==============================================================
  // 自分の学習時間
  // ==============================================================

  double get weeklyStudyHours {
    return widget.totalSeconds / 3600.0;
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

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          children: [
            // ======================================================
            // 比較条件
            // ======================================================
            _buildConditionCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 平均との比較
            // ======================================================
            _buildAverageCard(cardColor, textColor),

            const SizedBox(height: 14),

            // ======================================================
            // 比較グラフ
            // ======================================================
            _buildComparisonChart(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // ユーザー変更
            // ======================================================
            _buildUserChangeCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 比較まとめ
            // ======================================================
            _buildSummaryCard(cardColor, textColor, secondaryColor),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 比較条件
  // ==============================================================

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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _dropdown(
                  title: "期間を選択",
                  value: "8/16（日）- 8/22（土）",
                  textColor: textColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _dropdown(
                  title: "比較する相手",
                  value: comparisonTarget,
                  textColor: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF258EDB)),
              borderRadius: BorderRadius.circular(12),
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
                      "12,345 人",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Icon(Icons.info_outline, color: secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 平均との比較
  // ==============================================================

  Widget _buildAverageCard(Color cardColor, Color textColor) {
    const averageHours = 8.6;

    final difference = weeklyStudyHours - averageHours;

    return _card(
      cardColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "平均との比較",
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                "(今週)",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _comparisonValue(
                  "自分の学習時間",
                  weeklyStudyHours.toStringAsFixed(1),
                  "時間",
                  const Color(0xFF258EDB),
                ),
              ),

              _divider(),

              Expanded(
                child: _comparisonValue(
                  "平均学習時間",
                  averageHours.toStringAsFixed(1),
                  "時間",
                  textColor,
                ),
              ),

              _divider(),

              Expanded(
                child: _comparisonValue(
                  "差分",
                  "${difference >= 0 ? '+' : ''}"
                      "${difference.toStringAsFixed(1)}",
                  "時間",
                  const Color(0xFFE52B72),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFB300),
                size: 21,
              ),
              const SizedBox(width: 5),
              Text(
                difference >= 0 ? "平均より多い！" : "もう少し頑張ろう！",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 比較グラフ
  // ==============================================================

  Widget _buildComparisonChart(
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
            "学習時間の比較グラフ",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _buildPeriodSelector(),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legend(const Color(0xFF258EDB), "あなた"),
              const SizedBox(width: 14),
              _legend(const Color(0xFFBDBDBD), "全体平均"),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(height: 270, child: BarChart(_createChart())),

          const SizedBox(height: 5),

          Text(
            "※目標時間は日によって異なります",
            style: TextStyle(color: secondaryColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 週 / 月 / 年
  // ==============================================================

  Widget _buildPeriodSelector() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _periodButton("週", 0),
          _periodButton("月", 1),
          _periodButton("年", 2),
        ],
      ),
    );
  }

  Widget _periodButton(String title, int index) {
    final selected = selectedPeriod == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF258EDB) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ユーザー変更
  // ==============================================================

  Widget _buildUserChangeCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return _card(
      cardColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Color(0xFF258EDB),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "比較するユーザーを変更",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "特定のユーザーと比較して、"
                      "モチベーションを高めましょう！",
                      style: TextStyle(color: secondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _selectUser,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF258EDB),
                side: const BorderSide(color: Color(0xFF258EDB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "ユーザーを選択して比較する",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 比較まとめ
  // ==============================================================

  Widget _buildSummaryCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return _card(
      cardColor,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Color(0xFFFFB300),
            size: 38,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "比較のまとめ",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  "あなたの学習時間は、"
                  "全体の平均より +2.7 時間多いです！",
                  style: TextStyle(color: textColor, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  "この調子で目標達成を目指しましょう！",
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // グラフ
  // ==============================================================

  BarChartData _createChart() {
    final myValues = _myValues();

    final averageValues = [0.4, 0.9, 1.6, 2.3, 1.4, 1.6, 0.4];

    return BarChartData(
      maxY: 5,
      minY: 0,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              const labels = [
                "日\n8/16",
                "月\n8/17",
                "火\n8/18",
                "水\n8/19",
                "木\n8/20",
                "金\n8/21",
                "土\n8/22",
              ];

              if (index < 0 || index >= labels.length) {
                return const SizedBox();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),

        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      barGroups: List.generate(7, (index) {
        return BarChartGroupData(
          x: index,
          barsSpace: 3,
          barRods: [
            BarChartRodData(
              toY: myValues[index],
              width: 10,
              color: const Color(0xFF258EDB),
              borderRadius: BorderRadius.circular(4),
            ),

            BarChartRodData(
              toY: averageValues[index],
              width: 10,
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }

  List<double> _myValues() {
    final hours = weeklyStudyHours;

    return [
      hours * 0.04,
      hours * 0.10,
      hours * 0.17,
      hours * 0.30,
      hours * 0.15,
      hours * 0.20,
      hours * 0.04,
    ];
  }

  // ==============================================================
  // ユーザー選択
  // ==============================================================

  void _selectUser() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("比較するユーザー"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.groups, color: Color(0xFF258EDB)),
                title: const Text("全体のユーザー（平均）"),
                onTap: () {
                  setState(() {
                    comparisonTarget = "全体のユーザー（平均）";
                  });

                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.search),
                title: const Text("ユーザーを検索する"),
                onTap: () {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ユーザー検索は後で実装します")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==============================================================
  // 共通
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

  Widget _dropdown({
    required String title,
    required String value,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),

        const SizedBox(height: 7),

        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
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
      ],
    );
  }

  Widget _comparisonValue(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),

        const SizedBox(height: 10),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: " $unit",
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 65, color: Colors.grey.shade300);
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 5),

        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
