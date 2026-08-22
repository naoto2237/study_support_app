import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordMyRecordScreen2 extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color secondaryColor;
  final int selectedPeriod;
  final DateTime selectedWeekStart;
  final Map<String, int> studyRecords;
  final double currentStudyHours;
  final double weeklyStudyHours;
  final double weeklyGoalHours;
  final int achievementRate;
  final ValueChanged<int> onPeriodChanged;
  final ValueChanged<DateTime> onWeekChanged;

  const RecordMyRecordScreen2({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.secondaryColor,
    required this.selectedPeriod,
    required this.selectedWeekStart,
    required this.studyRecords,
    required this.currentStudyHours,
    required this.weeklyStudyHours,
    required this.weeklyGoalHours,
    required this.achievementRate,
    required this.onPeriodChanged,
    required this.onWeekChanged,
  });

  @override
  State<RecordMyRecordScreen2> createState() => _RecordMyRecordScreen2State();
}

class _RecordMyRecordScreen2State extends State<RecordMyRecordScreen2> {
  late int selectedPeriod;
  late DateTime selectedWeekStart;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.selectedPeriod;
    selectedWeekStart = widget.selectedWeekStart;
  }

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChartCard(
          widget.cardColor,
          widget.textColor,
          widget.secondaryColor,
        ),
        const SizedBox(height: 14),
        _buildGoalCard(
          widget.cardColor,
          widget.textColor,
          widget.secondaryColor,
        ),
        const SizedBox(height: 14),
        _buildReflectionCard(
          widget.cardColor,
          widget.textColor,
          widget.secondaryColor,
        ),
        const SizedBox(height: 14),
        _buildRecentRecords(
          widget.cardColor,
          widget.textColor,
          widget.secondaryColor,
        ),
      ],
    );
  }

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

                  widget.onWeekChanged(selectedWeekStart);
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

                  widget.onWeekChanged(selectedWeekStart);
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

          widget.onPeriodChanged(index);
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

        values[i] = (widget.studyRecords[key] ?? 0) / 3600.0;

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          values[i] += widget.currentStudyHours;
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
                  "${widget.weeklyGoalHours.toStringAsFixed(1)} 時間",
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
                "${widget.achievementRate} %",
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
                  value: widget.achievementRate / 100,
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
                  "${widget.weeklyStudyHours.toStringAsFixed(1)} "
                  "時間学習しました！",
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "目標まであと "
                  "${(widget.weeklyGoalHours - widget.weeklyStudyHours).clamp(0, double.infinity).toStringAsFixed(1)} "
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
