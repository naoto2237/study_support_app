// ======================================================================
// 【部品】「自分の記録」タブの学習時間グラフ（週／月／年の切り替え）
//
// 主なクラス: StudyTimeChartSection
// ・期間の切り替え、前後の週・月・年への移動、棒グラフ、目標と達成率
// ・その下に最近の記録（recent_records_section.dart）を表示
// ・旧ファイル名: record_myrecord_screen2.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/screens/record/my_record/recent_records_section.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/screens/record/chart_tooltip_layout.dart';
import 'package:study_support_app/main.dart' show currentDay, todayStudyLoaded;

class StudyTimeChartSection extends StatefulWidget {
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

  // 記録を読みこみ中か（読みこみ中は、合計と1日の平均を「--」にする）
  final bool isLoading;
  final ValueChanged<int> onPeriodChanged;
  final ValueChanged<DateTime> onWeekChanged;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  // 日付が変わって、表示する週・月・年が新しい今日に移ったとき
  final void Function(DateTime weekStart, DateTime month, int year)
  onDayFollowed;
  final String userId;

  const StudyTimeChartSection({
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
    this.isLoading = false,
    required this.onPeriodChanged,
    required this.onWeekChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onDayFollowed,
    required this.userId,
  });

  @override
  State<StudyTimeChartSection> createState() => _StudyTimeChartSectionState();
}

class _StudyTimeChartSectionState extends State<StudyTimeChartSection> {
  late int selectedPeriod;
  late DateTime selectedWeekStart;

  late int selectedYear;
  late DateTime selectedMonth;

  // タップしている棒の番号（タップしていないときは -1）
  int _touchedIndex = -1;

  // 押している位置（グラフの中の座標）。指を離すと null
  Offset? _touchPosition;

  // 左の目盛り（数字と単位）の幅
  // グラフの部品が教えてくる「押した位置」は、この幅を除いた場所から数えた値なので、
  // 吹き出しを置くときはこの幅を足す
  static const double _leftAxisWidth = 36;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.selectedPeriod;
    selectedWeekStart = widget.selectedWeekStart;

    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month, 1);
    selectedYear = now.year;

    _shownDay = DateTime(now.year, now.month, now.day);

    // 日付が変わったら（ホーム画面が知らせる）、表示する週・月・年を合わせる
    currentDay.addListener(_onDayChanged);
  }

  @override
  void dispose() {
    currentDay.removeListener(_onDayChanged);
    super.dispose();
  }

  // ==========================================================
  // 日付が変わったとき
  //
  // 「今日をふくむ週・月・年」を見ていたときだけ、新しい今日をふくむ
  // 週・月・年へ移る。前の週などに動かして見ているときは、そのままにする。
  // ==========================================================

  // グラフが「今日」として扱っている日（時刻は 0:00）
  late DateTime _shownDay;

  static DateTime _weekStartOf(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDayChanged() {
    final oldDay = _shownDay;
    final newDay = currentDay.value;

    if (_sameDay(oldDay, newDay) || !mounted) return;

    _shownDay = DateTime(newDay.year, newDay.month, newDay.day);

    final followWeek = _sameDay(selectedWeekStart, _weekStartOf(oldDay));
    final followMonth =
        selectedMonth.year == oldDay.year &&
        selectedMonth.month == oldDay.month;
    final followYear = selectedYear == oldDay.year;

    if (!followWeek && !followMonth && !followYear) return;

    setState(() {
      if (followWeek) selectedWeekStart = _weekStartOf(newDay);
      if (followMonth) selectedMonth = DateTime(newDay.year, newDay.month, 1);
      if (followYear) selectedYear = newDay.year;
    });

    // 学習記録の画面にも同じ週・月・年を伝える
    // （記録の読み直しは、学習記録の画面が日付の変わり目に行う）
    widget.onDayFollowed(selectedWeekStart, selectedMonth, selectedYear);
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

    return "$selectedYear年";
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

        RecentRecordsSection(
          userId: widget.userId,
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
          // 今日の時間の読みこみが終わったら描き直す
          ValueListenableBuilder<bool>(
            valueListenable: todayStudyLoaded,
            builder: (context, todayLoaded, child) {
              return _buildPeriodSummary(textColor, secondaryColor);
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BarChart(_createChart()),

                // 押している間だけ、押した位置の少し上に吹き出しを出す
                if (_touchedIndex >= 0 && _touchPosition != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomSingleChildLayout(
                        delegate: ChartTooltipLayoutDelegate(
                          _touchPosition! + const Offset(_leftAxisWidth, 0),
                        ),
                        child: _buildTouchTooltip(_touchedIndex),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 33,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.background,
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
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : widget.textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 吹き出し（押している棒の日付・時間・期間の何%か）
  // 見た目は前のグラフの部品の吹き出しと同じ（うすい青。色は app_colors.dart の tooltip〜）
  // ==========================================================
  Widget _buildTouchTooltip(int groupIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tooltipColor = isDark
        ? AppColors.tooltipBackgroundDark
        : AppColors.tooltipBackground;
    final tooltipBorderColor = isDark
        ? AppColors.tooltipBorderDark
        : AppColors.tooltipBorder;
    final tooltipTextColor = isDark
        ? AppColors.tooltipTextDark
        : AppColors.tooltipText;
    final tooltipSubColor = isDark
        ? AppColors.tooltipSubTextDark
        : AppColors.tooltipSubText;

    final hourValues = _chartValues();
    final labels = _chartLabels();

    if (groupIndex < 0 ||
        groupIndex >= labels.length ||
        groupIndex >= hourValues.length) {
      return const SizedBox.shrink();
    }

    final label = labels[groupIndex];

    // 期間の合計（「合計の何%か」を出すため）
    final totalSecondsInPeriod = hourValues.fold<double>(
      0,
      (total, v) => total + v * 3600,
    );

    String title;

    if (selectedPeriod == 0) {
      // 週
      final date = selectedWeekStart.add(Duration(days: groupIndex));

      const weekdays = ["月", "火", "水", "木", "金", "土", "日"];

      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      title =
          "${date.month}/${date.day}（${weekdays[date.weekday - 1]}）"
          "${isToday ? "・今日" : ""}";
    } else if (selectedPeriod == 1) {
      // 月
      final targetMonth = selectedMonth;

      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      // タップしたバーの週まで進める
      final weekStart = firstDay
          .subtract(Duration(days: firstDay.weekday - 1))
          .add(Duration(days: groupIndex * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // 月の範囲内だけ表示
      final displayStart = weekStart.isBefore(firstDay) ? firstDay : weekStart;
      final displayEnd = weekEnd.isAfter(lastDay) ? lastDay : weekEnd;

      title =
          "${groupIndex + 1}週目（"
          "${displayStart.month}/${displayStart.day}"
          "～"
          "${displayEnd.month}/${displayEnd.day}）";
    } else {
      // 年
      title = "$selectedYear年$label";
    }

    final seconds = (hourValues[groupIndex] * 3600).round();

    // 期間の合計のうち、この棒が何%か
    final percent = totalSecondsInPeriod > 0
        ? (seconds / totalSecondsInPeriod * 100).round()
        : 0;

    final periodName = selectedPeriod == 0
        ? "週"
        : selectedPeriod == 1
        ? "月"
        : "年";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tooltipColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tooltipBorderColor),
      ),
      child: Text.rich(
        TextSpan(
          text: "$title\n",
          style: TextStyle(
            color: tooltipSubColor,
            fontSize: 11,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: _formatTooltipTime(seconds),
              style: TextStyle(
                color: tooltipTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            if (seconds > 0)
              TextSpan(
                text: "\nこの$periodNameの $percent%",
                style: TextStyle(
                  color: tooltipSubColor,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  BarChartData _createChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hourValues = _chartValues();

    final maxHours = hourValues.isEmpty
        ? 0.0
        : hourValues.reduce((a, b) => a > b ? a : b);

    // ----------------------------------------------------------
    // 目盛りの単位
    // いちばん長い棒が1時間未満なら「分」、それ以外は「時間」。
    // （短い時間でも棒が点にならないようにする）
    // ----------------------------------------------------------
    final useMinutes = maxHours < 1;

    final values = useMinutes
        ? hourValues.map((v) => v * 60).toList()
        : hourValues;

    final maxValue = useMinutes ? maxHours * 60 : maxHours;

    // きりのいい上限を選ぶ（目盛りは5本）
    double maxY;

    if (useMinutes) {
      maxY = [
        5.0,
        10.0,
        15.0,
        30.0,
        60.0,
      ].firstWhere((candidate) => maxValue <= candidate, orElse: () => 60.0);
    } else {
      maxY = maxValue <= 5 ? 5.0 : (maxValue / 5).ceil() * 5.0;
    }

    final interval = maxY / 5;

    final unitLabel = useMinutes ? "分" : "時間";

    final currentIndex = _currentIndex();

    final gridColor = isDark ? Colors.white12 : AppColors.divider;

    return BarChartData(
      barTouchData: BarTouchData(
        enabled: true,

        // 押している棒と、押している位置を覚える
        // （その棒だけ色を濃くし、押した位置の少し上に吹き出しを出す。指を離すと消える）
        touchCallback: (event, response) {
          final index = event.isInterestedForInteractions
              ? (response?.spot?.touchedBarGroupIndex ?? -1)
              : -1;

          final position = index >= 0 ? event.localPosition : null;

          if (index != _touchedIndex || position != _touchPosition) {
            setState(() {
              _touchedIndex = index;
              _touchPosition = position;
            });
          }
        },

        // 吹き出しは、グラフの部品のものではなく、押した位置の少し上に自分で出す
        // （_buildTouchTooltip。グラフの部品の吹き出しは棒のてっぺんにしか出せないため）
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
        ),
      ),
      maxY: maxY,
      minY: 0,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 1),
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _leftAxisWidth,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // いちばん上の目盛りには単位（分・時間）を出す
              final number = value == value.roundToDouble()
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1);

              final text = value == meta.max ? unitLabel : number;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: widget.secondaryColor),
                ),
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

              // 週のグラフだけ、土曜は青・日曜は赤にする（月曜はじまり）
              Color labelColor = widget.secondaryColor;
              if (selectedPeriod == 0 && index == 5) {
                labelColor = AppColors.primary;
              } else if (selectedPeriod == 0 && index == 6) {
                labelColor = const Color(0xFFE5534B);
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: labelColor),
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
        // 今の日・週・月の棒だけ濃い青、ほかはうすい青
        final isCurrent = index == currentIndex;

        // タップしている棒も濃くする
        final isTouched = index == _touchedIndex;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              width: selectedPeriod == 2 ? 14 : 20,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: (isCurrent || isTouched)
                    ? const [AppColors.primaryDeep, AppColors.primaryLight]
                    : [
                        AppColors.primary.withValues(alpha: 0.45),
                        AppColors.primaryLight.withValues(alpha: 0.45),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              // 棒のうしろに、上限までのうすい土台を出す
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.background,
              ),
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

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          values[i] = widget.currentStudyHours;
        }
      }

      return values;
    }

    // ==========================================================
    // 月：カレンダーの週ごとに集計
    // 月曜日～日曜日
    // ==========================================================
    if (selectedPeriod == 1) {
      final targetMonth = selectedMonth;
      final now = DateTime.now();

      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);

      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      // 月の1日が何曜日か
      // DateTime.weekday:
      // 月=1、火=2、...、土=6、日=7
      // カレンダーの第1週の月曜日
      final firstDayOffset = firstDay.weekday - 1;

      DateTime weekStart = firstDay.subtract(Duration(days: firstDayOffset));

      final values = <double>[];

      while (!weekStart.isAfter(lastDay)) {
        double totalHours = 0;

        // 月曜日～日曜日
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));

          // 対象月以外の日は除外
          if (date.month != targetMonth.month ||
              date.year != targetMonth.year) {
            continue;
          }

          final key = "${date.year}/${date.month}/${date.day}";
          if (date.year == now.year &&
              date.month == now.month &&
              date.day == now.day) {
            totalHours += widget.currentStudyHours;
          } else {
            totalHours += (widget.studyRecords[key] ?? 0) / 3600.0;
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
    final now = DateTime.now();

    final values = List<double>.filled(12, 0);

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(targetYear, month + 1, 0).day;

      double totalHours = 0;

      for (int day = 1; day <= daysInMonth; day++) {
        final key = "$targetYear/$month/$day";

        if (targetYear == now.year && month == now.month && day == now.day) {
          // 今日だけリアルタイムの値を使用
          totalHours += widget.currentStudyHours;
        } else {
          totalHours += (widget.studyRecords[key] ?? 0) / 3600.0;
        }
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
      const week = ["月", "火", "水", "木", "金", "土", "日"];

      return List.generate(7, (index) {
        final date = selectedWeekStart.add(Duration(days: index));

        return "${week[date.weekday - 1]}\n"
            "${date.month}/${date.day}";
      });
    }

    // ==========================================================
    // 月
    // カレンダーの週に合わせる
    // ==========================================================
    if (selectedPeriod == 1) {
      final targetMonth = selectedMonth;

      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);

      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      final firstDayOffset = firstDay.weekday - 1;

      DateTime weekStart = firstDay.subtract(Duration(days: firstDayOffset));

      final labels = <String>[];

      int weekNumber = 1;

      while (!weekStart.isAfter(lastDay)) {
        labels.add("$weekNumber週目");

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

  // ==========================================================
  // 期間の合計と1日の平均
  // ==========================================================

  // 表示している期間の、最初の日と最後の日
  (DateTime, DateTime) _periodRange() {
    if (selectedPeriod == 0) {
      final start = DateTime(
        selectedWeekStart.year,
        selectedWeekStart.month,
        selectedWeekStart.day,
      );
      return (start, start.add(const Duration(days: 6)));
    }

    if (selectedPeriod == 1) {
      return (
        DateTime(selectedMonth.year, selectedMonth.month, 1),
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
      );
    }

    return (DateTime(selectedYear, 1, 1), DateTime(selectedYear, 12, 31));
  }

  // 平均を出すときの日数（期間のうち、今日までの日数）
  int _elapsedDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final (start, end) = _periodRange();

    if (today.isBefore(start)) return 0;

    final last = today.isBefore(end) ? today : end;

    return last.difference(start).inDays + 1;
  }

  // 吹き出し用：1時間未満は秒まで（「15分27秒」）、1時間以上は分まで（「1時間5分」）
  String _formatTooltipTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return minutes > 0 ? "$hours時間$minutes分" : "$hours時間";
    }

    if (minutes > 0) {
      return "$minutes分$remainingSeconds秒";
    }

    return "$remainingSeconds秒";
  }

  // 期間の合計と1日の平均：上のサマリー（my_record_screen.dart の formatPeriodStudyTime）と同じ書き方
  // 1時間未満は秒まで（「0分44秒」）、100時間未満は「3時間12分」、100時間以上は「120.5時間」
  String _formatTotal(int totalSeconds) {
    if (totalSeconds >= 100 * 3600) {
      final tenthsOfHour = (totalSeconds * 10) ~/ 3600;
      return "${tenthsOfHour ~/ 10}.${tenthsOfHour % 10}時間";
    }

    if (totalSeconds < 3600) {
      return "${totalSeconds ~/ 60}分${totalSeconds % 60}秒";
    }

    return "${totalSeconds ~/ 3600}時間${(totalSeconds % 3600) ~/ 60}分";
  }

  Widget _buildPeriodSummary(Color textColor, Color secondaryColor) {
    final values = _chartValues();

    final totalSeconds = (values.fold<double>(0, (sum, v) => sum + v) * 3600)
        .round();

    final days = _elapsedDays();
    final averageSeconds = days > 0 ? totalSeconds ~/ days : 0;

    // 記録か今日の時間を読みこみ中なら、正しい数字が出るまで「--」にする
    final loading = widget.isLoading || !todayStudyLoaded.value;

    final periodName = selectedPeriod == 0
        ? "この週"
        : selectedPeriod == 1
        ? "この月"
        : "この年";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$periodNameの合計",
                style: TextStyle(color: secondaryColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              _timeText(
                loading ? "--" : _formatTotal(totalSeconds),
                // 合計の数字・単位は緑（1日の平均は青のまま）
                color: AppColors.green,
                numberSize: 25,
                unitSize: 14,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "1日の平均",
              style: TextStyle(color: secondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 2),
            _timeText(
              loading ? "--" : _formatTotal(averageSeconds),
              color: AppColors.primary,
              numberSize: 18,
              unitSize: 12,
            ),
          ],
        ),
      ],
    );
  }

  // 「23分」「1時間5分」を、数字は Roboto で大きく、単位は小さく出す
  // （上のサマリーカードの数字と同じ書き方にそろえる）
  Widget _timeText(
    String value, {
    required Color color,
    required double numberSize,
    required double unitSize,
  }) {
    // 読みこみ中の「--」
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

    // 「120.5時間」のような小数も、ひとかたまりの数字として出す
    final spans = RegExp(r'(\d+(?:\.\d+)?)(時間|分|秒)').allMatches(value).expand((
      m,
    ) {
      return [
        TextSpan(
          text: m.group(1),
          style: GoogleFonts.roboto(
            color: color,
            fontSize: numberSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: m.group(2),
          style: TextStyle(
            color: color,
            fontSize: unitSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }).toList();

    return RichText(text: TextSpan(children: spans));
  }

  // 今の日・週・月にあたる棒の番号（表示している期間に今日がなければ -1）
  int _currentIndex() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final (start, end) = _periodRange();

    if (today.isBefore(start) || today.isAfter(end)) return -1;

    if (selectedPeriod == 0) {
      return today.difference(start).inDays;
    }

    if (selectedPeriod == 1) {
      // カレンダーの第1週の月曜日から数える
      final firstMonday = start.subtract(Duration(days: start.weekday - 1));
      return today.difference(firstMonday).inDays ~/ 7;
    }

    return today.month - 1;
  }

  Widget _card(Color color, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
