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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white70 : Colors.black87;

        String todayKey = formatDate(selectedDay);

        int currentDaySeconds = (studyRecords[todayKey] ?? 0);
        int displaySeconds = widget.totalSeconds > 0 ? widget.totalSeconds : currentDaySeconds;

        int totalMinutes = displaySeconds ~/ 60;
        double totalHours = displaySeconds / 3600.0;
        int streakDays = calculateStreak();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              "学習グラフ",
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            backgroundColor: cardColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: IconButton(
                  icon: Icon(Icons.notifications_none, color: textColor),
                  onPressed: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: IconButton(
                  icon: Icon(Icons.settings_outlined, color: textColor),
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
            iconTheme: IconThemeData(color: textColor),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A) : Colors.lightBlue.shade300,
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
                    color: cardColor,
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
                              color: isWeek ? Colors.lightBlue : cardColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "週",
                                style: TextStyle(
                                  color: isWeek ? Colors.white : textColor,
                                  fontWeight: FontWeight.bold,
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
                              color: isWeek ? cardColor : Colors.lightBlue,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "日",
                                style: TextStyle(
                                  color: isWeek ? textColor : Colors.white,
                                  fontWeight: FontWeight.bold,
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
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: textColor),
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

                Expanded(child: BarChart(createChart(isDark, textColor))),
              ],
            ),
          ),
        );
      },
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

  BarChartData createChart(bool isDark, Color textColor) {
    final gridColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

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
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: gridColor,
          strokeWidth: 1,
        ),
      ),
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
                  style: TextStyle(fontSize: 11, color: textColor),
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

class RecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 学習記録を追加
  Future<void> addRecord({
    required String subject,
    required int studyTime,
    required String memo,
  }) async {
    await _firestore.collection("records").add({
      "subject": subject,
      "studyTime": studyTime,
      "memo": memo,
      "date": Timestamp.now(),
    });
  }

  // 学習記録を取得
  Stream<QuerySnapshot> getRecords() {
    return _firestore
        .collection("records")
        .orderBy(
      "date",
      descending: true,
    )
        .snapshots();
  }

  // 学習記録を削除
  Future<void> deleteRecord(String id) async {
    await _firestore.collection("records").doc(id).delete();
  }

  // 学習時間の合計
  Future<int> getTotalStudyTime() async {
    final snapshot = await _firestore.collection("records").get();

    int total = 0;

    for (var doc in snapshot.docs) {
      total += doc["studyTime"] as int;
    }

    return total;
  }

  // 指定した期間の学習記録取得
  Future<List<QueryDocumentSnapshot>> getRecordsByDate(
      DateTime start,
      DateTime end,
      ) async {
    final snapshot = await _firestore
        .collection("records")
        .where(
      "date",
      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
    )
        .where(
      "date",
      isLessThanOrEqualTo: Timestamp.fromDate(end),
    )
        .get();

    return snapshot.docs;
  }
}