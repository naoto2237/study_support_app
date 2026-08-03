import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:study_support_app/setting_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool isWeek = true;

  // 週表示用（日曜日スタート）
  DateTime selectedWeekStart = DateTime(2026, 7, 12);

  // 日表示用
  DateTime selectedDay = DateTime(2026, 7, 13);

  final List<double> weeklyHours = [8, 8.5, 11, 8.3, 4.2, 13.5, 7.8];

  final List<double> dailyHours = [1, 2, 3, 2, 4, 5, 2, 1];

  final List<String> dayLabels = ["0", "3", "6", "9", "12", "15", "18", "21"];

  String formatDate(DateTime date) {
    return "${date.year}/${date.month}/${date.day}";
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
                  infoRow("今月学習時間", "156時間"),

                  const SizedBox(height: 8),

                  infoRow("前月比", "+4時間"),

                  const SizedBox(height: 8),

                  infoRow("連続学習", "15日"),
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
    final values = isWeek ? weeklyHours : dailyHours;

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
