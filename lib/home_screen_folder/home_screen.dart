import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/setting_screen.dart';
import 'package:study_support_app/main.dart' as app; // ← 'app' という名前のあだ名を付ける
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/chat_list_screen.dart';
import 'package:study_support_app/main.dart' as app;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:study_support_app/timer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 停止済みの学習時間
  Duration todayTotal = Duration.zero;
  Duration _displayTime = Duration.zero;
  Duration _sessionTime = Duration.zero;
  Duration _baseTime = Duration.zero;

  String getToday() {
    final now = DateTime.now();
    const weeks = ["月", "火", "水", "木", "金", "土", "日"];

    return "${now.year}年${now.month}月${now.day}日(${weeks[now.weekday - 1]})";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final divColor1 = isDark ? Colors.grey.shade800 : const Color(0xFFB5BDC7);

    final divColor2 = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,

      // ==========================================================
      // AppBar
      // ==========================================================
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFF258EDB),

        title: const Text(
          "ホーム",
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ), // ※ファイル名に合わせて変更
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.notifications_none), // 吹き出しアイコン
              onPressed: () {},
            ),
          ),
        ],

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ==========================================================
      // Body
      // ==========================================================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====================================================
              // 日付
              // ====================================================
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF258EDB),
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      getToday(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ====================================================
              // タイマー
              // ====================================================
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: double.infinity,
                  child: StopwatchWidget(
                    onSaveStudyTime: saveTodayStudyTime,

                    // タイマー動作中の画面表示だけ更新
                    onTick: (sessionTime) {
                      app.todayStudySeconds.value =
                          todayTotal.inSeconds + sessionTime.inSeconds;
                    },

                    // 停止・リセットしたときに確定
                    onStop: (sessionTime) {
                      setState(() {
                        todayTotal += sessionTime;
                      });

                      app.todayStudySeconds.value = todayTotal.inSeconds;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ====================================================
              // 今日の目標
              // ====================================================
              ValueListenableBuilder<double>(
                valueListenable: app.dailyTargetHours,

                builder: (context, targetHoursValue, child) {
                  final goalTime = Duration(
                    hours: targetHoursValue.floor(),
                    minutes:
                        ((targetHoursValue - targetHoursValue.floor()) * 60)
                            .round(),
                  );

                  // ------------------------------------------------
                  // 今日の学習時間をリアルタイム監視
                  // ------------------------------------------------
                  return ValueListenableBuilder<int>(
                    valueListenable: app.todayStudySeconds,

                    builder: (context, studySeconds, child) {
                      final studyTime = Duration(seconds: studySeconds);

                      // 達成率
                      final progress = goalTime.inSeconds > 0
                          ? studySeconds / goalTime.inSeconds
                          : 0.0;

                      // 残り時間
                      final remainingTime = goalTime - studyTime;

                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: Card(
                            elevation: 0,
                            color: cardColor,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: divColor2, width: 1),
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ==================================
                                // タイトル
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 13,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.flag_rounded,
                                        size: 24,
                                        color: Color(0xFFFF2D55),
                                      ),

                                      const SizedBox(width: 6),

                                      Text(
                                        "今日の目標",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: divColor1,
                                ),

                                // ==================================
                                // 目標時間・達成率
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 7,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        "${goalTime.inHours}時間"
                                        "${goalTime.inMinutes % 60}分",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.trending_up_rounded,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "達成率",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
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
                                              minHeight: 7,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              color: const Color(0xFF42A5F5),
                                              backgroundColor: const Color(
                                                0xFFBBDEFB,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Text(
                                            "${(progress * 100).toStringAsFixed(0)}%",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 0),

                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: divColor2,
                                ),

                                const SizedBox(height: 4),

                                // ==================================
                                // 今日の学習時間
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "今日の学習時間",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),

                                          const Spacer(),

                                          Text(
                                            "${studyTime.inHours}時間"
                                            "${studyTime.inMinutes % 60}分",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
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
                                  color: divColor2,
                                ),

                                const SizedBox(height: 4),

                                // ==================================
                                // 目標まで残り
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "目標まで残り",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),

                                          const Spacer(),

                                          Text(
                                            remainingTime.isNegative
                                                ? "達成済み！"
                                                : "${remainingTime.inHours}時間"
                                                      "${remainingTime.inMinutes % 60}分",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveTodayStudyTime(int seconds) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || seconds <= 0) return;

    // 今日の日付
    final now = DateTime.now();

    final dateId =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final studyRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("studyRecords")
        .doc(dateId);

    // その日の学習時間に加算
    await studyRef.set({
      "studyTime": FieldValue.increment(seconds),
      "date": dateId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ================================================================
// 学習タイマー
// ================================================================

// ================================================================
// 学習タイマー
// ================================================================
class StopwatchWidget extends StatefulWidget {
  final Function(Duration) onStop;
  final Future<void> Function(int seconds) onSaveStudyTime;
  final Function(Duration)? onTick;

  const StopwatchWidget({
    super.key,
    required this.onStop,
    required this.onSaveStudyTime,
    this.onTick,
  });

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  @override
  void initState() {
    super.initState();

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (!mounted) return;

    if (data is Map) {
      final value = data['totalMilliseconds'];

      if (value is int) {
        setState(() {
          _totalDisplayTime = Duration(milliseconds: value);

          _currentSessionTime = _totalDisplayTime - _sessionStartTotal;
        });

        widget.onTick?.call(_currentSessionTime);
      }
    }
  }

  // ==============================================================
  // 内部タイマー
  // ==============================================================

  // 画面に表示する累計時間
  Duration _totalDisplayTime = Duration.zero;

  // 現在のセッション開始時点での累計時間
  Duration _sessionStartTotal = Duration.zero;

  // 現在のセッションで経過した時間
  Duration _currentSessionTime = Duration.zero;

  final Stopwatch _stopwatch = Stopwatch();

  DateTime? _timerStartTime;

  Timer? _timer;

  Future<void> _requestNotificationPermission() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  // ==============================================================
  // 開始
  // ==============================================================

  Future<void> _start() async {
    if (_stopwatch.isRunning) return;

    await _requestNotificationPermission();

    // 開始時点の累計時間
    _sessionStartTotal = _totalDisplayTime;

    _currentSessionTime = Duration.zero;

    // Stopwatchは「開始中かどうか」の管理だけに使う
    _stopwatch.reset();
    _stopwatch.start();

    // Foreground Service開始
    await FlutterForegroundTask.startService(
      notificationTitle: '学習中',
      notificationText: _formatTime(),
      callback: startCallback,
    );

    // 現在の累計時間だけServiceへ渡す
    FlutterForegroundTask.sendDataToTask({
      'baseMilliseconds': _sessionStartTotal.inMilliseconds,
    });

    setState(() {});
  }

  // ==============================================================
  // 停止
  // ==============================================================

  Future<void> _stop() async {
    if (!_stopwatch.isRunning) return;

    _stopwatch.stop();

    // Serviceを停止する前に、
    // 最後に受け取った時間を現在値として使う
    final sessionTime = _totalDisplayTime - _sessionStartTotal;

    await FlutterForegroundTask.stopService();

    _currentSessionTime = sessionTime;

    if (mounted) {
      setState(() {});
    }

    if (sessionTime > Duration.zero) {
      try {
        await widget.onSaveStudyTime(sessionTime.inSeconds);

        widget.onStop(sessionTime);
      } catch (e) {
        debugPrint('学習時間の保存に失敗しました: $e');
      }
    }

    _stopwatch.reset();
    _currentSessionTime = Duration.zero;

    // _totalDisplayTime はそのまま
  }

  // ==============================================================
  // リセット
  // ==============================================================
  Future<void> _reset() async {
    // 動いていたら停止
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }

    _timer?.cancel();
    _timer = null;

    // Foreground Serviceを停止
    await FlutterForegroundTask.stopService();

    // リセット直前のセッション時間
    final sessionTime = _totalDisplayTime - _sessionStartTotal;

    // ----------------------------------------
    // リセット前のセッションを保存
    // ----------------------------------------

    if (sessionTime > Duration.zero) {
      try {
        await widget.onSaveStudyTime(sessionTime.inSeconds);

        widget.onStop(sessionTime);
      } catch (e) {
        debugPrint('学習時間の保存に失敗しました: $e');
      }
    }

    // ----------------------------------------
    // 完全リセット
    // ----------------------------------------

    _stopwatch.reset();

    _currentSessionTime = Duration.zero;
    _sessionStartTotal = Duration.zero;
    _totalDisplayTime = Duration.zero;

    if (!mounted) return;

    setState(() {});
  }

  // ==============================================================
  // 時間表示
  // ==============================================================

  String _formatTime() {
    final hours = _totalDisplayTime.inHours.toString().padLeft(2, '0');

    final minutes = (_totalDisplayTime.inMinutes % 60).toString().padLeft(
      2,
      '0',
    );

    final seconds = (_totalDisplayTime.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return '$hours:$minutes:$seconds';
  }

  // ==============================================================
  // dispose
  // ==============================================================

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();

    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);

    super.dispose();
  }

  // ==============================================================
  // UI
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 7,
      shadowColor: const Color(0xFF258EDB).withValues(alpha: 0.39),
      color: const Color(0xFF258EDB),
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

            const SizedBox(height: 3),

            Text(
              _formatTime(),
              style: GoogleFonts.roboto(
                fontSize: 37,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.9,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ==================================================
                // 開始 / 停止
                // ==================================================
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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _stopwatch.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF258EDB),
                          size: 35,
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

                // ==================================================
                // リセット
                // ==================================================
                GestureDetector(
                  onTap: _reset,
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF258EDB),
                          size: 35,
                        ),
                      ),

                      const SizedBox(height: 0),

                      const Text(
                        "リセット",
                        style: TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
