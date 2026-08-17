import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/setting_screen.dart';
import 'package:study_support_app/main.dart'; // ★ main.dart から共有の isDarkModeNotifier を読み込む

class RecordScreen extends StatefulWidget {
  final int totalSeconds;

  const RecordScreen({super.key, required this.totalSeconds});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool isWeek = true;

  @override
  void didUpdateWidget(covariant RecordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalSeconds != widget.totalSeconds) {
      setState(() {});
    }
  }

  // 週表示用の基準日
  DateTime selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  // 日表示用の選択日
  DateTime selectedDay = DateTime.now();

  final List<String> dayLabels = ["0", "3", "6", "9", "12", "15", "18", "21"];

  // 日付ごとの学習時間を保持するマップ
  final Map<String, int> studyRecords = {};

  String formatDate(DateTime date) {
    return "${date.year}/${date.month}/${date.day}";
  }

  // 連続学習日数を計算するロジック
  int calculateStreak() {
    if (widget.totalSeconds > 0) {
      return 1;
    }
    return 0;
  }

  List<String> getWeekLabels() {
    const week = ["日", "月", "火", "水", "木", "金", "土"];

    return List.generate(7, (index) {
      DateTime date = selectedWeekStart.add(Duration(days: index));

      return "${week[date.weekday % 7]}\n"
          "${date.month}/${date.day}";
    });
  }

  @override
  Widget build(BuildContext context) {
    String todayKey = formatDate(selectedDay);

    int currentDaySeconds = (studyRecords[todayKey] ?? 0);
    int displaySeconds = widget.totalSeconds > 0 ? widget.totalSeconds : currentDaySeconds;

    int totalMinutes = displaySeconds ~/ 60;
    double totalHours = displaySeconds / 3600.0;
    int streakDays = calculateStreak();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          "学習グラフ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  infoRow("選択日の学習時間", "${totalMinutes}分 (${totalHours.toStringAsFixed(1)}時間)"),
                  const SizedBox(height: 8),
                  infoRow("累計学習時間", "${totalHours.toStringAsFixed(1)}時間"),
                  const SizedBox(height: 8),
                  infoRow("連続学習", "$streakDays日"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 週・日切り替え
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isWeek = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isWeek ? Colors.lightBlue : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "週",
                            style: TextStyle(
                              color: isWeek ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isWeek = false;
                          selectedDay = DateTime.now();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isWeek ? Colors.white : Colors.lightBlue,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "日",
                            style: TextStyle(
                              color: isWeek ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 日付移動部分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      if (isWeek) {
                        selectedWeekStart = selectedWeekStart.subtract(
                          const Duration(days: 7),
                        );
                      } else {
                        selectedDay = selectedDay.subtract(
                          const Duration(days: 1),
                        );
                      }
                    });
                  },
                ),
                Text(
                  isWeek
                      ? "${formatDate(selectedWeekStart)} ～ "
                      "${formatDate(selectedWeekStart.add(const Duration(days: 6)))}"
                      : formatDate(selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      if (isWeek) {
                        selectedWeekStart = selectedWeekStart.add(
                          const Duration(days: 7),
                        );
                      } else {
                        selectedDay = selectedDay.add(const Duration(days: 1));
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(child: BarChart(createChart())),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  BarChartData createChart() {
    List<double> values = [];

    if (isWeek) {
      values = List.generate(7, (index) {
        DateTime date = selectedWeekStart.add(Duration(days: index));
        String key = formatDate(date);
        int seconds = studyRecords[key] ?? 0;

        if (date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day) {
          seconds += widget.totalSeconds;
        }
        return seconds / 3600.0;
      });
    } else {
      // 日表示の場合：現在の時間帯（0, 3, 6, 9, 12, 15, 18, 21時台）に自動で反映させる
      values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      double todayHours = widget.totalSeconds / 3600.0;
      if (todayHours > 0) {
        int currentHour = DateTime.now().hour;
        int timeIndex = (currentHour ~/ 3).clamp(0, 7);
        values[timeIndex] = todayHours;
      }
    }

    final labels = isWeek ? getWeekLabels() : dayLabels;

    return BarChartData(
      maxY: 16,
      minY: 0,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 2,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: textColor, fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= labels.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
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
              width: 18,
              borderRadius: BorderRadius.circular(6),
              color: Colors.lightBlue,
            ),
          ],
        );
      }),
    );
  }
}