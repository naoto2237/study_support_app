import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'record_myrecord_screen3.dart';

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
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<int> onYearChanged;

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
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  State<RecordMyRecordScreen2> createState() => _RecordMyRecordScreen2State();
}

class _RecordMyRecordScreen2State extends State<RecordMyRecordScreen2> {
  late int selectedPeriod;
  late DateTime selectedWeekStart;

  late int selectedYear;
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.selectedPeriod;
    selectedWeekStart = widget.selectedWeekStart;

    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month, 1);
    selectedYear = now.year;
  }

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}";
  }

  String _periodDateText() {
    if (selectedPeriod == 0) {
      final end = selectedWeekStart.add(const Duration(days: 6));

      return "${formatDate(selectedWeekStart)} - "
          "${formatDate(end)}";
    }

    if (selectedPeriod == 1) {
      return "${selectedMonth.year}年"
          "${selectedMonth.month}月";
    }

    return "${selectedYear}年";
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

        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
          child: Text(
            "グラフの表示には時間がかかる場合があります",
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.secondaryColor, fontSize: 11),
          ),
        ),

        const SizedBox(height: 14),

        RecordMyRecordScreen3(
          cardColor: widget.cardColor,
          textColor: widget.textColor,
          secondaryColor: widget.secondaryColor,
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
                    if (selectedPeriod == 0) {
                      selectedWeekStart = selectedWeekStart.subtract(
                        const Duration(days: 7),
                      );

                      widget.onWeekChanged(selectedWeekStart);
                    } else if (selectedPeriod == 1) {
                      // 前月
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month - 1,
                        1,
                      );
                      widget.onMonthChanged(selectedMonth);
                    } else {
                      // 前年
                      selectedYear--;
                      widget.onYearChanged(selectedYear);
                    }
                  });
                },

                icon: Icon(Icons.chevron_left, color: textColor),
              ),

              Text(
                _periodDateText(),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    if (selectedPeriod == 0) {
                      selectedWeekStart = selectedWeekStart.add(
                        const Duration(days: 7),
                      );

                      widget.onWeekChanged(selectedWeekStart);
                    } else if (selectedPeriod == 1) {
                      // 次月
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month + 1,
                        1,
                      );
                      widget.onMonthChanged(selectedMonth);
                    } else {
                      // 次年
                      selectedYear++;
                      widget.onYearChanged(selectedYear);
                    }
                  });
                },
                icon: Icon(Icons.chevron_right, color: textColor),
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

    // データに合わせて最大値を自動調整
    final maxValue = values.isEmpty
        ? 5.0
        : values.reduce((a, b) => a > b ? a : b);

    final maxY = maxValue <= 5 ? 5.0 : (maxValue / 5).ceil() * 5.0;

    return BarChartData(
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.white,
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final labels = _chartLabels();

            if (groupIndex < 0 || groupIndex >= labels.length) {
              return null;
            }

            final label = labels[groupIndex];

            String title;

            if (selectedPeriod == 0) {
              // 週
              final date = selectedWeekStart.add(Duration(days: groupIndex));

              const weekdays = ["月", "火", "水", "木", "金", "土", "日"];

              title =
                  "${date.month}/${date.day}（${weekdays[date.weekday - 1]}）";
            } else if (selectedPeriod == 1) {
              // 月
              final targetMonth = selectedMonth;

              final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);

              final lastDay = DateTime(
                targetMonth.year,
                targetMonth.month + 1,
                0,
              );

              final firstDayOffset = firstDay.weekday % 7;

              DateTime weekStart = firstDay.subtract(
                Duration(days: firstDayOffset),
              );

              // タップしたバーの週まで進める
              weekStart = weekStart.add(Duration(days: groupIndex * 7));

              DateTime weekEnd = weekStart.add(const Duration(days: 6));

              // 月の範囲内だけ表示
              final displayStart = weekStart.isBefore(firstDay)
                  ? firstDay
                  : weekStart;

              final displayEnd = weekEnd.isAfter(lastDay) ? lastDay : weekEnd;

              title =
                  "${groupIndex + 1}週目\n"
                  "${displayStart.month}/${displayStart.day}"
                  "～"
                  "${displayEnd.month}/${displayEnd.day}";
            } else {
              // 年
              title = label;
            }

            final totalSeconds = (rod.toY * 3600).round();

            final hours = totalSeconds ~/ 3600;
            final minutes = (totalSeconds % 3600) ~/ 60;

            String timeText;

            if (hours > 0) {
              timeText = "${hours}時間";
              if (minutes > 0) {
                timeText += "${minutes}分";
              }
            } else {
              timeText = "${minutes}分";
            }

            return BarTooltipItem(
              "$title\n",
              const TextStyle(
                color: Color(0xFF202124),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              children: [
                TextSpan(
                  text: timeText,
                  style: const TextStyle(
                    color: Color(0xFF202124),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      maxY: maxY,
      minY: 0,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY <= 10 ? 1 : 5,
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: maxY <= 10 ? 1 : 5,
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
              width: selectedPeriod == 2 ? 12 : 17,
              color: const Color(0xFF258EDB),
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        );
      }),
    );
  }

  List<double> _chartValues() {
    // ==========================================================
    // 週：7日分の日別学習時間
    // ==========================================================
    if (selectedPeriod == 0) {
      final values = List<double>.filled(7, 0);
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = selectedWeekStart.add(Duration(days: i));

        final key = "${date.year}/${date.month}/${date.day}";

        values[i] = (widget.studyRecords[key] ?? 0) / 3600.0;

        // 今日の学習中の時間をリアルタイムで加算
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          values[i] += widget.currentStudyHours;
        }
      }

      return values;
    }

    // ==========================================================
    // 月：カレンダーの週ごとに集計
    // 日曜日～土曜日
    // ==========================================================
    if (selectedPeriod == 1) {
      final targetMonth = selectedMonth;
      final now = DateTime.now();

      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);

      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      // 月の1日が何曜日か
      // DateTime.weekday:
      // 月=1、火=2、...、土=6、日=7
      // カレンダー上の日曜=0に変換
      final firstDayOffset = firstDay.weekday % 7;

      // カレンダーの第1週の日曜日
      DateTime weekStart = firstDay.subtract(Duration(days: firstDayOffset));

      final values = <double>[];

      while (!weekStart.isAfter(lastDay)) {
        double totalHours = 0;

        // 日曜日～土曜日
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));

          // 対象月以外の日は除外
          if (date.month != targetMonth.month ||
              date.year != targetMonth.year) {
            continue;
          }

          final key = "${date.year}/${date.month}/${date.day}";

          totalHours += (widget.studyRecords[key] ?? 0) / 3600.0;

          // 今日のリアルタイム学習時間
          if (date.year == now.year &&
              date.month == now.month &&
              date.day == now.day) {
            totalHours += widget.currentStudyHours;
          }
        }

        values.add(totalHours);

        // 次の週へ
        weekStart = weekStart.add(const Duration(days: 7));
      }

      return values;
    }

    // ==========================================================
    // 年：1月～12月の月別学習時間
    // ==========================================================
    final targetYear = selectedYear;

    final values = List<double>.filled(12, 0);

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(targetYear, month + 1, 0).day;

      double totalHours = 0;

      for (int day = 1; day <= daysInMonth; day++) {
        final key = "${targetYear}/$month/$day";

        totalHours += (widget.studyRecords[key] ?? 0) / 3600.0;
      }

      // 今月ならリアルタイム時間も加算
      if (targetYear == DateTime.now().year && month == DateTime.now().month) {
        totalHours += widget.currentStudyHours;
      }

      values[month - 1] = totalHours;
    }

    return values;
  }

  List<String> _chartLabels() {
    // ==========================================================
    // 週
    // ==========================================================
    if (selectedPeriod == 0) {
      const week = ["日", "月", "火", "水", "木", "金", "土"];

      return List.generate(7, (index) {
        final date = selectedWeekStart.add(Duration(days: index));

        return "${week[date.weekday % 7]}\n"
            "${date.month}/${date.day}";
      });
    }

    // ==========================================================
    // 月
    // カレンダーの週に合わせる
    // ==========================================================
    if (selectedPeriod == 1) {
      final targetMonth = selectedMonth;
      final now = DateTime.now();

      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);

      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      final firstDayOffset = firstDay.weekday % 7;

      DateTime weekStart = firstDay.subtract(Duration(days: firstDayOffset));

      final labels = <String>[];

      int weekNumber = 1;

      while (!weekStart.isAfter(lastDay)) {
        labels.add("${weekNumber}週目");

        weekNumber++;

        weekStart = weekStart.add(const Duration(days: 7));
      }

      return labels;
    }

    // ==========================================================
    // 年
    // ==========================================================
    return List.generate(12, (index) => "${index + 1}月");
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

  Widget _card(Color color, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
