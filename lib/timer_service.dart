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

  @override
  Future<void> onStart(
      DateTime timestamp,
      TaskStarter starter,
      ) async {
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

    _updateTime();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateTime();
  }

  void _updateTime() {
    if (_startTimeMilliseconds == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // HomeScreenと同じ計算
    final elapsedMilliseconds =
        now - _startTimeMilliseconds!;

    final totalMilliseconds =
        _baseMilliseconds + elapsedMilliseconds;

    // 通知を更新
    _updateNotification(
      Duration(milliseconds: totalMilliseconds),
    );

    // HomeScreenへ同じ時間を送る
    FlutterForegroundTask.sendDataToMain({
      'totalMilliseconds': totalMilliseconds,
    });
  }

  void _updateNotification(Duration duration) {
    final hours =
    duration.inHours.toString().padLeft(2, '0');

    final minutes =
    (duration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final seconds =
    (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    FlutterForegroundTask.updateService(
      notificationTitle: '学習中',
      notificationText:
      '$hours:$minutes:$seconds',
    );
  }

  @override
  Future<void> onDestroy(
      DateTime timestamp,
      bool isTimeout,
      ) async {
    FlutterForegroundTask.sendDataToMain({
      'timerDestroyed': true,
    });
  }

  // 通知の「停止」ボタンが押されたとき
  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      // HomeScreenへ停止命令を送る
      FlutterForegroundTask.sendDataToMain({
        'stopTimer': true,
      });
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}