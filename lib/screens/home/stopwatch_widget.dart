// ======================================================================
// 【部品】学習タイマー（ホーム画面の中に表示）
//
// 主なクラス: StopwatchWidget
// ・開始／停止／リセット、経過時間の表示
// ・アプリを閉じても動くよう、通知のタイマー（services/timer_service.dart）とやり取りする
// ・停止したときに学習時間を保存する（onSaveStudyTime）
// ・カードを左右にスライドすると「増えるタイマー」と「減るタイマー」が切り替わる
//   （減るタイマーは、数字か右上の札を押して時間を決める。0になったら止めて記録する）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
// ← 'app' という名前のあだ名を付ける
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:study_support_app/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_support_app/theme/app_colors.dart';

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

    // 1枚目（増えるタイマー）から表示する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && !_isCountdown) {
        _pageController.jumpTo(0);
      }
    });
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    // 前に決めた減るタイマーの時間（一度も決めていなければ 0時間0分）
    // ※ 試しに保存していた古い値（countdownTargetMinutes）は使わずに消す
    await prefs.remove('countdownTargetMinutes');
    final savedMinutes = prefs.getInt('countdownTargetMinutesV2');
    if (savedMinutes != null && savedMinutes >= 0) {
      _countdownTarget = Duration(minutes: savedMinutes);
      if (mounted) setState(() {});
    }

    final isRunning = prefs.getBool('studyTimerRunning') ?? false;

    if (!isRunning) return;

    // 減るタイマーで計測していたか
    final countdownTarget = prefs.getInt('studyTimerCountdownTarget');
    if (countdownTarget != null) {
      _isCountdown = true;
      _countdownTarget = Duration(milliseconds: countdownTarget);

      // 減るタイマーのカード（2枚目）を表示する
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpTo(_pageController.position.maxScrollExtent);
        }
      });
    }

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

    final finished = _clampCountdown();

    setState(() {});

    widget.onTick?.call(_currentSessionTime);

    // アプリを閉じているあいだに減るタイマーが0になっていたら、止めて記録する
    if (finished) {
      await _stop();
      return;
    }

    _scheduleNextTick(startTime);
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
      // 減るタイマーが0になった（通知の側で気づいたとき）
      // ==========================================================
      if (data['countdownFinished'] == true) {
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
        await prefs.remove('studyTimerCountdownTarget');

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
        if (!_stopwatch.isRunning) return;

        var finished = false;

        setState(() {
          _totalDisplayTime = Duration(milliseconds: value);

          _currentSessionTime = _totalDisplayTime - _sessionStartTotal;

          finished = _clampCountdown();
        });

        widget.onTick?.call(_currentSessionTime);

        if (finished) await _stop();
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

  // ---------------- 減るタイマー ----------------
  // false: 増えるタイマー / true: 減るタイマー
  bool _isCountdown = false;

  // 減るタイマーの設定時間
  Duration _countdownTarget = Duration.zero;

  // ページを切り替えたとき、もう片方のタイマーの経過時間を取っておく
  Duration _otherModeTotal = Duration.zero;

  // 2枚のカードを横にめくるためのもの
  final ScrollController _pageController = ScrollController();

  // 減るタイマーが0を越えないようにする。0になっていたら true を返す
  bool _clampCountdown() {
    if (!_isCountdown) return false;

    if (_totalDisplayTime >= _countdownTarget) {
      _totalDisplayTime = _countdownTarget;
      _currentSessionTime = _totalDisplayTime - _sessionStartTotal;
      return true;
    }

    return false;
  }

  // 次の「秒の変わり目」に合わせて表示を更新する。
  // Timer.periodic(1秒) だと、開始した瞬間を基準に更新されるうえ
  // 少しずつ遅れるので、通知の表示と秒の切り替わりがずれていた。
  void _scheduleNextTick(int startTime) {
    _timer?.cancel();

    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    final total = _sessionStartTotal.inMilliseconds + elapsed;

    // 累計時間が次の1秒に届くまでの時間（+5ms で確実に越える）
    final wait = 1000 - (total % 1000) + 5;

    _timer = Timer(Duration(milliseconds: wait), () {
      if (!_stopwatch.isRunning || !mounted) return;

      final elapsedMilliseconds =
          DateTime.now().millisecondsSinceEpoch - startTime;

      var finished = false;

      setState(() {
        _currentSessionTime = Duration(milliseconds: elapsedMilliseconds);

        _totalDisplayTime = _sessionStartTotal + _currentSessionTime;

        finished = _clampCountdown();
      });

      widget.onTick?.call(_currentSessionTime);

      // 減るタイマーが0になったら、止めて記録する
      if (finished) {
        _stop();
        return;
      }

      _scheduleNextTick(startTime);
    });
  }

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

    // 減るタイマーの時間が0のときは、先に時間を選んでもらう
    if (_isCountdown && _countdownTarget == Duration.zero) {
      await _pickCountdownTime();
      return;
    }

    // 減るタイマーが0のまま開始したら、最初からやり直す
    if (_isCountdown && _totalDisplayTime >= _countdownTarget) {
      _totalDisplayTime = Duration.zero;
    }

    _sessionAlreadySaved = false;

    // ----------------------------------------------------------
    // 押した瞬間に開始時刻を決めて、画面をすぐ「計測中」にする。
    // （以前は許可の確認・保存・通知の起動を待ってから切り替えていたので、
    //   ボタンを押してから少し遅れて見えた）
    // ----------------------------------------------------------
    final startTime = DateTime.now().millisecondsSinceEpoch;
    _timerStartTime = DateTime.fromMillisecondsSinceEpoch(startTime);

    // 開始時点の累計時間
    _sessionStartTotal = _totalDisplayTime;

    _currentSessionTime = Duration.zero;

    // Stopwatchは開始中かどうかの管理だけ
    _stopwatch.reset();
    _stopwatch.start();

    // 秒の変わり目ごとにタイマーを更新
    // （通知と同じタイミングで秒が変わるようにする）
    _scheduleNextTick(startTime);

    if (mounted) {
      setState(() {});
    }

    // ----------------------------------------------------------
    // ここから先は、画面が切り替わったあとで行う
    // ----------------------------------------------------------
    await _requestNotificationPermission();

    // 許可の確認のあいだに停止された場合は、ここで終わる
    if (!_stopwatch.isRunning) return;

    // 開始時刻を保存
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('studyTimerRunning', true);

    await prefs.setInt('studyTimerStartTime', startTime);

    await prefs.setInt(
      'studyTimerBaseMilliseconds',
      _sessionStartTotal.inMilliseconds,
    );

    // 減るタイマーなら設定時間も保存（アプリを開き直したときに使う）
    if (_isCountdown) {
      await prefs.setInt(
        'studyTimerCountdownTarget',
        _countdownTarget.inMilliseconds,
      );
    } else {
      await prefs.remove('studyTimerCountdownTarget');
    }

    // 保存のあいだに停止された場合は、保存した開始時刻を消して終わる
    if (!_stopwatch.isRunning) {
      await prefs.setBool('studyTimerRunning', false);
      await prefs.remove('studyTimerStartTime');
      await prefs.remove('studyTimerBaseMilliseconds');
      await prefs.remove('studyTimerCountdownTarget');
      return;
    }

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
      // 減るタイマーのときだけ設定時間を渡す（増えるタイマーは null）
      'countdownTargetMilliseconds': _isCountdown
          ? _countdownTarget.inMilliseconds
          : null,
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
    // 最後の時間を確定（減るタイマーは設定時間を越えないようにする）
    _clampCountdown();
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
    await prefs.remove('studyTimerCountdownTarget');
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
    await prefs.remove('studyTimerCountdownTarget');

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

  // countdown / total を省くと、今えらんでいるタイマーの時間になる
  String _formatTime({bool? countdown, Duration? total}) {
    // 増えるタイマー：たまった時間（秒は切り捨て）
    // 減るタイマー：残りの時間（秒は切り上げ。60:00 から始まり、1秒たつと 59:59）
    // どちらも同じ瞬間に秒が変わる（通知の表示とも同じ）
    final isCountdown = countdown ?? _isCountdown;
    final elapsed = total ?? _totalDisplayTime;

    int totalSeconds;

    if (isCountdown) {
      final remaining =
          _countdownTarget.inMilliseconds - elapsed.inMilliseconds;
      totalSeconds = remaining <= 0 ? 0 : (remaining + 999) ~/ 1000;
    } else {
      totalSeconds = elapsed.inSeconds;
    }

    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = (totalSeconds ~/ 60 % 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // 「60分」「1時間30分」のような書き方
  String _targetLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;

    if (d == Duration.zero) return '時間を設定';
    if (h == 0) return '$m分';
    if (m == 0) return '$h時間';
    return '$h時間$m分';
  }

  // ==============================================================
  // 増えるタイマー ⇔ 減るタイマー の切り替え（カードを横にめくる）
  // ==============================================================

  // めくり終わったときに呼ぶ。countdown: 2枚目（減るタイマー）になったか
  void _setMode(bool countdown) {
    if (countdown == _isCountdown) return;

    // 計測中は切り替えない（めくれないようにしてあるが念のため）
    if (_stopwatch.isRunning) return;

    setState(() {
      // それぞれのタイマーの時間は、切り替えても残しておく
      final current = _totalDisplayTime;
      _totalDisplayTime = _otherModeTotal;
      _otherModeTotal = current;

      _sessionStartTotal = _totalDisplayTime;
      _currentSessionTime = Duration.zero;

      _isCountdown = !_isCountdown;
    });
  }

  // ==============================================================
  // 減るタイマーの時間を決める
  // ==============================================================

  Future<void> _pickCountdownTime() async {
    if (_stopwatch.isRunning) return;

    var selected = _countdownTarget;

    final result = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 18, 17, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'タイマーの時間',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // すぐ選べる時間
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [15, 30, 45, 60, 90].map((m) {
                        final isSelected = selected.inMinutes == m;

                        return ChoiceChip(
                          label: Text('$m分'),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: const StadiumBorder(),
                          onSelected: (_) {
                            setSheetState(() {
                              selected = Duration(minutes: m);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    // 時間・分を回して選ぶ
                    SizedBox(
                      height: 180,
                      child: CupertinoTimerPicker(
                        // 上のボタンを押したときも回る部分が動くよう、key を変える
                        key: ValueKey(selected.inMinutes),
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: selected,
                        onTimerDurationChanged: (value) {
                          selected = value;
                        },
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext, selected);
                        },
                        child: const Text(
                          '決定',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted || _stopwatch.isRunning) return;

    final target = Duration(minutes: result.inMinutes);

    setState(() {
      _countdownTarget = target;

      // 時間を決め直したら、最初から数える
      // （途中まで計った分は、停止したときに記録ずみ）
      _totalDisplayTime = Duration.zero;
      _sessionStartTotal = Duration.zero;
      _currentSessionTime = Duration.zero;
    });

    // 決めた時間を保存（次に開いたときも同じ時間になる）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('countdownTargetMinutesV2', target.inMinutes);
  }

  // ==============================================================
  // dispose
  // ==============================================================

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _pageController.dispose();

    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);

    super.dispose();
  }

  // ==============================================================
  // UI
  // ==============================================================

  // アプリでいつも使っている青
  static const Color _blue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;

    return LayoutBuilder(
      builder: (context, constraints) {
        // カードの幅（ホームの左右の余白17を引いた幅）
        final cardWidth = constraints.maxWidth;

        // めくるときは、画面の端から端まで使う
        // （となりのカードが画面の外から入ってくるように見せる）
        final screenWidth = MediaQuery.of(context).size.width;
        final side = ((screenWidth - cardWidth) / 2).clamp(0.0, 100.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 高さはカードに合わせ、横だけ画面の端まで広げる
            IntrinsicHeight(
              child: OverflowBox(
                minWidth: screenWidth,
                maxWidth: screenWidth,
                child: NotificationListener<ScrollNotification>(
                  // めくっている途中も位置を見て、半分を越えたら切り替える
                  // （めくり終わりの合図だけだと、切り替わらないことがあった）
                  onNotification: (notification) {
                    if (notification.metrics.axis != Axis.horizontal) {
                      return false;
                    }
                    final page = (notification.metrics.pixels / screenWidth)
                        .round();
                    _setMode(page == 1);
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    // 1枚ずつぴったり止まる。計測中はめくれない
                    physics: isRunning
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final countdownCard in [false, true])
                          SizedBox(
                            width: screenWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: _buildCard(
                                countdownCard: countdownCard,
                                isRunning: isRunning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // 今どちらのカードか（●○）。左：増える／右：減る
            // ==================================================
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageDot(!_isCountdown),
                const SizedBox(width: 6),
                _pageDot(_isCountdown),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // カード1枚分（countdownCard: 減るタイマーのカードか）
  // ==============================================================
  Widget _buildCard({required bool countdownCard, required bool isRunning}) {
    // このカードが今えらばれているカードか
    final isActive = countdownCard == _isCountdown;

    // えらばれていないカードは、取っておいた時間を表示する
    final total = isActive ? _totalDisplayTime : _otherModeTotal;

    final running = isActive && isRunning;

    // 減るタイマーで止まっているときは、時間を決められる
    final canPickTime = countdownCard && !running;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // グラデーションはやめて、アプリの青1色にする
        color: _blue,
      ),
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // 見出し（計測中は「計測中」の札、減るタイマーは設定時間の札）
          // ======================================================
          Row(
            children: [
              Icon(
                countdownCard
                    ? Icons.hourglass_bottom_rounded
                    : Icons.timer_outlined,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                countdownCard ? "学習タイマー（残り時間）" : "学習タイマー",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (canPickTime)
                GestureDetector(
                  onTap: isActive ? _pickCountdownTime : null,
                  child: _badge(
                    children: [
                      Text(
                        _targetLabel(_countdownTarget),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                )
              else
                AnimatedOpacity(
                  opacity: running ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _badge(
                    children: const [
                      Icon(Icons.circle, size: 8, color: Color(0xFFFF5A7A)),
                      SizedBox(width: 5),
                      Text(
                        "計測中",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // ======================================================
          // 時間（大きく、数字の幅をそろえてちらつかないように）
          // 減るタイマーで止まっているときは、押すと時間を決められる
          // ======================================================
          GestureDetector(
            onTap: canPickTime && isActive ? _pickCountdownTime : null,
            // 文字が大きい設定でもはみ出さないよう、入りきらないときだけ縮める
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatTime(countdown: countdownCard, total: total),
                style: GoogleFonts.roboto(
                  fontSize: 43,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // 開始 / 停止（大きな横長ボタン）・リセット（小さいボタン）
          // ======================================================
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isActive
                        ? () {
                            if (_stopwatch.isRunning) {
                              _stop();
                            } else {
                              _start();
                            }
                          }
                        : null,
                    child: SizedBox(
                      height: 43,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: _blue,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            running ? "停止" : "開始",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _blue,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Material(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isActive ? _reset : null,
                  child: const SizedBox(
                    width: 50,
                    height: 43,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "リセット",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 見出しの右の、うすい白の札
  Widget _badge({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  // カードの下の点（今のカードは横長の青、もう片方は灰色）
  Widget _pageDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 14 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
