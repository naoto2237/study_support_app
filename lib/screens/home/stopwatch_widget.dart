// ======================================================================
// 【部品】学習タイマー（ホーム画面の中に表示）
//
// 主なクラス: StopwatchWidget
// ・開始／停止／リセット、経過時間の表示
// ・アプリを閉じても動くよう、通知のタイマー（services/timer_service.dart）とやり取りする
// ・停止したときに学習時間を保存する（onSaveStudyTime）
// ======================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
// ← 'app' という名前のあだ名を付ける
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:study_support_app/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _restoreTimerState();
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    final isRunning = prefs.getBool('studyTimerRunning') ?? false;

    if (!isRunning) return;

    final startTime = prefs.getInt('studyTimerStartTime');

    final baseMilliseconds = prefs.getInt('studyTimerBaseMilliseconds') ?? 0;

    if (startTime == null) return;

    final elapsedMilliseconds =
        DateTime.now().millisecondsSinceEpoch - startTime;

    _sessionStartTotal = Duration(milliseconds: baseMilliseconds);

    _totalDisplayTime = Duration(
      milliseconds: baseMilliseconds + elapsedMilliseconds,
    );

    _currentSessionTime = Duration(milliseconds: elapsedMilliseconds);

    _stopwatch.start();

    if (!mounted) return;

    setState(() {});

    widget.onTick?.call(_currentSessionTime);
  }

  Future<void> _onReceiveTaskData(Object data) async {
    if (!mounted) return;

    if (data is Map) {
      // ==========================================================
      // 通知の「停止」ボタンが押された
      // ==========================================================
      if (data['stopTimer'] == true) {
        await _stop();
        return;
      }

      // ==========================================================
      // タスクキル・Foreground Service終了
      // ==========================================================
      if (data['timerDestroyed'] == true) {
        _timer?.cancel();
        _timer = null;

        _stopwatch.stop();

        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('studyTimerRunning', false);
        await prefs.remove('studyTimerStartTime');
        await prefs.remove('studyTimerBaseMilliseconds');

        if (!mounted) return;

        setState(() {
          _currentSessionTime = Duration.zero;
        });

        return;
      }

      // ==========================================================
      // 通常のタイマー更新
      // ==========================================================
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
  bool _sessionAlreadySaved = false;
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

    _sessionAlreadySaved = false;

    await _requestNotificationPermission();

    // 開始時点の累計時間
    _sessionStartTotal = _totalDisplayTime;

    _currentSessionTime = Duration.zero;

    // Stopwatchは開始中かどうかの管理だけ
    _stopwatch.reset();
    _stopwatch.start();

    // 開始時刻を保存
    final prefs = await SharedPreferences.getInstance();

    final startTime = DateTime.now().millisecondsSinceEpoch;
    _timerStartTime = DateTime.fromMillisecondsSinceEpoch(startTime);

    await prefs.setBool('studyTimerRunning', true);

    await prefs.setInt('studyTimerStartTime', startTime);

    await prefs.setInt(
      'studyTimerBaseMilliseconds',
      _sessionStartTotal.inMilliseconds,
    );

    // ----------------------------------------------------------
    // 1秒ごとにタイマーを更新
    // ----------------------------------------------------------
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_stopwatch.isRunning) return;

      final elapsedMilliseconds =
          DateTime.now().millisecondsSinceEpoch - startTime;

      if (!mounted) return;

      setState(() {
        _currentSessionTime = Duration(milliseconds: elapsedMilliseconds);

        _totalDisplayTime = _sessionStartTotal + _currentSessionTime;
      });

      widget.onTick?.call(_currentSessionTime);
    });

    // ----------------------------------------------------------
    // Foreground Service開始
    // ----------------------------------------------------------
    await FlutterForegroundTask.startService(
      notificationTitle: '学習中',
      notificationText: _formatTime(),
      callback: startCallback,
      notificationButtons: [const NotificationButton(id: 'stop', text: '停止')],
    );
    // Serviceへ現在の累計時間を渡す
    // Serviceへタイマー開始時刻と累計時間を渡す
    FlutterForegroundTask.sendDataToTask({
      'startTimeMilliseconds': startTime,
      'baseMilliseconds': _sessionStartTotal.inMilliseconds,
    });

    if (mounted) {
      setState(() {});
    }
  }

  // ==============================================================
  // 停止
  // ==============================================================

  Future<void> _stop() async {
    if (!_stopwatch.isRunning) return;

    _stopwatch.stop();

    // 1秒タイマーを停止
    _timer?.cancel();
    _timer = null;

    // Serviceを停止する前に、
    // 最後の時間を確定
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

        _sessionAlreadySaved = true;
      } catch (e) {
        debugPrint('学習時間の保存に失敗しました: $e');
      }
    }

    _stopwatch.reset();

    // 停止した時点の表示時間は残す
    _currentSessionTime = sessionTime;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('studyTimerRunning', false);

    await prefs.remove('studyTimerStartTime');

    await prefs.remove('studyTimerBaseMilliseconds');
  }

  // ==============================================================
  // リセット
  // ==============================================================
  Future<void> _reset() async {
    // 現在動作中なら、今回のセッション時間を計算
    Duration sessionTime = Duration.zero;

    if (!_sessionAlreadySaved) {
      sessionTime = _totalDisplayTime - _sessionStartTotal;
    }

    // タイマー停止
    _stopwatch.stop();

    _timer?.cancel();
    _timer = null;

    // Foreground Service停止
    await FlutterForegroundTask.stopService();

    // まだ保存されていない場合だけ保存
    if (!_sessionAlreadySaved && sessionTime > Duration.zero) {
      try {
        await widget.onSaveStudyTime(sessionTime.inSeconds);

        widget.onStop(sessionTime);

        _sessionAlreadySaved = true;
      } catch (e) {
        debugPrint('学習時間の保存に失敗しました: $e');
      }
    }

    // 保存情報を削除
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('studyTimerRunning', false);

    await prefs.remove('studyTimerStartTime');

    await prefs.remove('studyTimerBaseMilliseconds');

    // 完全リセット
    _stopwatch.reset();

    _currentSessionTime = Duration.zero;
    _sessionStartTotal = Duration.zero;
    _totalDisplayTime = Duration.zero;
    _timerStartTime = null;

    _sessionAlreadySaved = false;

    if (!mounted) return;

    setState(() {});

    widget.onTick?.call(Duration.zero);
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
