import 'package:flutter/material.dart';
import 'dart:async';

import 'package:study_support_app/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  // ★ 親から関数を受け取る窓口を追加
  final Function(int)? onStudyFinished;

  const HomeScreen({super.key, this.onStudyFinished});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Duration todayTotal = Duration.zero;

  String getToday() {
    final now = DateTime.now();
    const weeks = ["月", "火", "水", "木", "金", "土", "日"];
    return "${now.year}年${now.month}月${now.day}日(${weeks[now.weekday - 1]})";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: const Text(
          "ホーム",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getToday(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: double.infinity,
                  child: StopwatchWidget(
                    onStop: (time) {
                      setState(() {
                        todayTotal += time;
                      });

                      // ★ 追加：親（main.dart）へ測った秒数を教える
                      if (widget.onStudyFinished != null) {
                        widget.onStudyFinished!(time.inSeconds);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ★ 設定画面の目標時間とリアルタイム連動させるためのビルダー
              ValueListenableBuilder<double>(
                valueListenable: dailyTargetHours,
                builder: (context, targetHoursValue, child) {
                  // 設定された時間（例: 3.5時間）を Duration に変換
                  Duration goalTime = Duration(
                    hours: targetHoursValue.floor(),
                    minutes: ((targetHoursValue - targetHoursValue.floor()) * 60).round(),
                  );

                  // 達成率の計算
                  double progress = goalTime.inSeconds > 0
                      ? todayTotal.inSeconds / goalTime.inSeconds
                      : 0.0;

                  // 残り時間の計算
                  Duration remainingTime = goalTime - todayTotal;

                  return Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // タイトル
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 14,
                                bottom: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 19,
                                    color: Color(0xFFFF2D55),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "今日の目標",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 1,
                              width: double.infinity,
                              color: const Color(0xFFB5BDC7),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 9,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "${goalTime.inHours}時間${goalTime.inMinutes % 60}分",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.trending_up_rounded,
                                        size: 17,
                                        color: Color(0xFF2196F3),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "達成率",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 2),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: progress.clamp(0.0, 1.0),
                                          minHeight: 10,
                                          borderRadius: BorderRadius.circular(9),
                                          color: const Color(0xFF42A5F5),
                                          backgroundColor: const Color(0xFFBBDEFB),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${(progress * 100).toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),

                            Container(
                              height: 1,
                              width: double.infinity,
                              color: const Color(0xFFE5E7EB),
                            ),

                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "今日の学習時間",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "${todayTotal.inHours}時間${todayTotal.inMinutes % 60}分",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: const Color(0xFFE5E7EB),
                            ),

                            const SizedBox(height: 0),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "目標まで残り",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        remainingTime.isNegative
                                            ? "達成済み！"
                                            : "${remainingTime.inHours}時間${remainingTime.inMinutes % 60}分",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// StopwatchWidget のコードはそのまま
class StopwatchWidget extends StatefulWidget {
  final Function(Duration) onStop;

  const StopwatchWidget({super.key, required this.onStop});

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  void _start() {
    if (_stopwatch.isRunning) return;

    _stopwatch.start();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {});
    });
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();

    widget.onStop(_stopwatch.elapsed);
  }

  void _reset() {
    _stop();
    _stopwatch.reset();
    setState(() {});
  }

  String _formatTime() {
    final elapsed = _stopwatch.elapsed;

    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (elapsed.inMilliseconds % 1000 ~/ 100).toString();

    return "$hours:$minutes:$seconds.$milliseconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 9,
      shadowColor: const Color(0xFF2196F3).withValues(alpha: 0.34),
      color: const Color(0xFF2196F3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "学習タイマー",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 1),

            Text(
              _formatTime(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 9),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_stopwatch.isRunning) {
                      _stop();
                    } else {
                      _start();
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _stopwatch.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF2196F3),
                          size: 33,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stopwatch.isRunning ? "停止" : "開始",
                        style: const TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _reset,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF2196F3),
                          size: 33,
                        ),
                      ),
                      const SizedBox(height: 0),
                      const Text(
                        "リセット",
                        style: TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}