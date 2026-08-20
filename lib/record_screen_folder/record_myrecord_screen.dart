import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RecordMyRecordScreen extends StatefulWidget {
  final int totalSeconds;

  const RecordMyRecordScreen({super.key, required this.totalSeconds});

  @override
  State<RecordMyRecordScreen> createState() => _RecordMyRecordScreenState();
}

class _RecordMyRecordScreenState extends State<RecordMyRecordScreen> {
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

  // ==============================================================
  // 学習時間
  // ==============================================================

  double get currentStudyHours {
    return widget.totalSeconds / 3600.0;
  }

  double get weeklyStudyHours {
    double total = 0;

    studyRecords.forEach((key, seconds) {
      total += seconds / 3600.0;
    });

    total += currentStudyHours;

    return total;
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
    if (widget.totalSeconds > 0) {
      return 1;
    }

    return 0;
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

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          children: [
            // ======================================================
            // 今週のサマリー
            // ======================================================
            _buildSummaryCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 学習記録の推移
            // ======================================================
            _buildChartCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 週間目標
            // ======================================================
            _buildGoalCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 学習のふりかえり
            // ======================================================
            _buildReflectionCard(cardColor, textColor, secondaryColor),

            const SizedBox(height: 14),

            // ======================================================
            // 最近の学習記録
            // ======================================================
            _buildRecentRecords(cardColor, textColor, secondaryColor),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 今週のサマリー
  // ==============================================================

  Widget _buildSummaryCard(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "今週のサマリー",
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

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: "今日の学習時間",
                  value: weeklyStudyHours.toStringAsFixed(1),
                  unit: "時間",
                  color: const Color(0xFF258EDB),
                  bottomText: "目標 ${weeklyGoalHours.toStringAsFixed(1)} 時間",
                ),
              ),

              _divider(),

              Expanded(
                child: _summaryItem(
                  title: "今週の学習時間",
                  value: averageDailyGoal.toStringAsFixed(1),
                  unit: "時間/日",
                  color: textColor,
                  bottomText: '',
                //  bottomText: "※日によって異なります",
                ),
              ),

              _divider(),

              Expanded(
                child: _summaryItem(
                  title: "目標達成日数",
                  value: calculateStreak().toString(),
                  unit: "日",
                  color: textColor,
                  bottomText: '',
                  //bottomText: "目標に向けてコツコツ！",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 学習記録の推移
  // ==============================================================

  Widget _buildChartCard(
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
            "学習記録の推移",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _buildPeriodSelector(),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedWeekStart = selectedWeekStart.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                "${formatDate(selectedWeekStart)} - "
                "${formatDate(selectedWeekStart.add(const Duration(days: 6)))}",
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    selectedWeekStart = selectedWeekStart.add(
                      const Duration(days: 7),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legend(const Color(0xFF258EDB), "学習時間"),
              const SizedBox(width: 14),
              _legend(const Color(0xFFBDBDBD), "目標時間"),
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
      height: 33,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
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
  // グラフ
  // ==============================================================

  BarChartData _createChart() {
    final values = _chartValues();

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

              final labels = _chartLabels();

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

      barGroups: List.generate(values.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              width: 17,
              color: const Color(0xFF258EDB),
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        );
      }),
    );
  }

  List<double> _chartValues() {
    if (selectedPeriod == 0) {
      final values = List<double>.filled(7, 0);

      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = selectedWeekStart.add(Duration(days: i));

        final key = "${date.year}/${date.month}/${date.day}";

        values[i] = (studyRecords[key] ?? 0) / 3600.0;

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          values[i] += currentStudyHours;
        }
      }

      return values;
    }

    if (selectedPeriod == 1) {
      return [2.0, 3.5, 4.0, 2.5];
    }

    return [18, 24, 21, 28, 25, 31, 27, 30, 22, 26, 29, 32];
  }

  List<String> _chartLabels() {
    if (selectedPeriod == 0) {
      const week = ["日", "月", "火", "水", "木", "金", "土"];

      return List.generate(7, (index) {
        final date = selectedWeekStart.add(Duration(days: index));

        return "${week[date.weekday % 7]}\n"
            "${date.month}/${date.day}";
      });
    }

    if (selectedPeriod == 1) {
      return ["1週目", "2週目", "3週目", "4週目"];
    }

    return [
      "1月",
      "2月",
      "3月",
      "4月",
      "5月",
      "6月",
      "7月",
      "8月",
      "9月",
      "10月",
      "11月",
      "12月",
    ];
  }

  // ==============================================================
  // 週間目標
  // ==============================================================

  Widget _buildGoalCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return _card(
      cardColor,
      Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes,
              color: Color(0xFF258EDB),
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "週間目標",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "今週の目標合計",
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
                Text(
                  "${weeklyGoalHours.toStringAsFixed(1)} 時間",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 65, color: Colors.grey.shade300),

          const SizedBox(width: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "達成率",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              Text(
                "$achievementRate %",
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              SizedBox(
                width: 105,
                child: LinearProgressIndicator(
                  value: achievementRate / 100,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF258EDB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ふりかえり
  // ==============================================================

  Widget _buildReflectionCard(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return _card(
      cardColor,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.article_outlined, color: Color(0xFF258EDB)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "学習のふりかえり",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  "今週は合計 "
                  "${weeklyStudyHours.toStringAsFixed(1)} "
                  "時間学習しました！",
                  style: TextStyle(color: textColor, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  "目標まであと "
                  "${(weeklyGoalHours - weeklyStudyHours).clamp(0, double.infinity).toStringAsFixed(1)} "
                  "時間です。もう少しで達成できます！",
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
  // 最近の学習記録
  // ==============================================================

  Widget _buildRecentRecords(
    Color cardColor,
    Color textColor,
    Color secondaryColor,
  ) {
    return _card(
      cardColor,
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "最近の学習記録",
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                "すべて見る  ›",
                style: TextStyle(color: secondaryColor, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _recordItem(
            "8/22（土）",
            "数学 / 微分積分",
            "1.5時間",
            textColor,
            secondaryColor,
          ),

          _recordItem(
            "8/21（金）",
            "英語 / 単語暗記",
            "1.0時間",
            textColor,
            secondaryColor,
          ),

          _recordItem("8/20（木）", "物理 / 力学", "1.2時間", textColor, secondaryColor),
        ],
      ),
    );
  }

  Widget _recordItem(
    String date,
    String subject,
    String time,
    Color textColor,
    Color secondaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              date,
              style: TextStyle(color: secondaryColor, fontSize: 12),
            ),
          ),

          Expanded(
            child: Text(
              subject,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),

          Text(time, style: TextStyle(color: textColor, fontSize: 13)),

          const SizedBox(width: 4),

          Icon(Icons.chevron_right, color: secondaryColor, size: 20),
        ],
      ),
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

  Widget _summaryItem({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required String bottomText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11)),

        const SizedBox(height: 9),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 25,
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

        const SizedBox(height: 8),

        Text(bottomText, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 75, color: Colors.grey.shade300);
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
