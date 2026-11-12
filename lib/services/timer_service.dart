// ======================================================================
// 学習タイマーの通知（フォアグラウンドサービス）
//
// 主なクラス: StudyTimerTaskHandler
// ・アプリを閉じても通知にタイマーを表示し続ける
// ・ホーム画面（home_screen.dart）と経過時間や「停止」をやり取りする
// ======================================================================

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StudyTimerTaskHandler());
}

class StudyTimerTaskHandler extends TaskHandler {
  // HomeScreenと同じ開始時刻
  int? _startTimeMilliseconds;

  // 開始時点までの累計時間
  int _baseMilliseconds = 0;

  // 最後に通知に出した秒（同じ秒のあいだは書き換えない）
  int? _lastShownSecond;

  // 減るタイマーの設定時間（増えるタイマーのときは null）
  int? _countdownTargetMilliseconds;

  // 減るタイマーが0になったか
  bool _countdownFinished = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // HomeScreenから開始時刻を受け取る
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    // HomeScreenから開始時刻を受け取る
    final startTime = data['startTimeMilliseconds'];

    if (startTime is int) {
      _startTimeMilliseconds = startTime;
    }

    // HomeScreenから開始前までの累計時間を受け取る
    final baseTime = data['baseMilliseconds'];

    if (baseTime is int) {
      _baseMilliseconds = baseTime;
    }

    // 減るタイマーの設定時間（増えるタイマーのときは null）
    final target = data['countdownTargetMilliseconds'];
    _countdownTargetMilliseconds = target is int ? target : null;
    _countdownFinished = false;

    _lastShownSecond = null;
    _updateTime();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateTime();
  }

  void _updateTime() {
    if (_startTimeMilliseconds == null) return;

    // 減るタイマーが0になったあとは、何もしない（ホームが止めるのを待つ）
    if (_countdownFinished) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // HomeScreenと同じ計算
    final elapsedMilliseconds = now - _startTimeMilliseconds!;

    final totalMilliseconds = _baseMilliseconds + elapsedMilliseconds;

    final target = _countdownTargetMilliseconds;

    // ----------------------------------------------------------
    // 減るタイマーが0になった
    // ----------------------------------------------------------
    if (target != null && totalMilliseconds >= target) {
      _countdownFinished = true;

      FlutterForegroundTask.updateService(
        notificationTitle: '学習タイマー',
        notificationText: '終了',
      );

      // ホームへ知らせて、止めて記録してもらう
      FlutterForegroundTask.sendDataToMain({
        'totalMilliseconds': target,
        'countdownFinished': true,
      });
      return;
    }

    // 通知に出す秒（増える：たまった時間・切り捨て／減る：残り時間・切り上げ）
    // ホームの表示と同じ計算なので、同じ瞬間に秒が変わる
    final shownSeconds = target == null
        ? totalMilliseconds ~/ 1000
        : (target - totalMilliseconds + 999) ~/ 1000;

    // 秒の数字が変わったときだけ通知を書き換える。
    // 書き換えが多すぎると Android が間引いて、通知の表示が遅れるため。
    if (shownSeconds == _lastShownSecond) return;
    _lastShownSecond = shownSeconds;

    // 通知を更新
    _updateNotification(shownSeconds, isCountdown: target != null);

    // HomeScreenへ同じ時間を送る
    FlutterForegroundTask.sendDataToMain({
      'totalMilliseconds': totalMilliseconds,
    });
  }

  void _updateNotification(int totalSeconds, {required bool isCountdown}) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');

    final minutes = (totalSeconds ~/ 60 % 60).toString().padLeft(2, '0');

    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    FlutterForegroundTask.updateService(
      notificationTitle: '学習中',
      notificationText: isCountdown
          ? '残り $hours:$minutes:$seconds'
          : '$hours:$minutes:$seconds',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    FlutterForegroundTask.sendDataToMain({'timerDestroyed': true});
  }

  // 通知の「停止」ボタンが押されたとき
  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      // HomeScreenへ停止命令を送る
      FlutterForegroundTask.sendDataToMain({'stopTimer': true});
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
