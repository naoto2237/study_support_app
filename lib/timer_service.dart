import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    StudyTimerTaskHandler(),
  );
}

class StudyTimerTaskHandler extends TaskHandler {
  DateTime? _startTime;

  // Service開始時点までの累計時間
  int _baseMilliseconds = 0;

  @override
  Future<void> onStart(
      DateTime timestamp,
      TaskStarter starter,
      ) async {
    _startTime = timestamp;

    _updateTime(timestamp);
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final value = data['baseMilliseconds'];

      if (value is int) {
        _baseMilliseconds = value;

        // ここでは時間計算をしない
        // onRepeatEvent()で計算する
        _updateNotification(
          Duration(milliseconds: _baseMilliseconds),
        );

        FlutterForegroundTask.sendDataToMain({
          'totalMilliseconds': _baseMilliseconds,
        });
      }
    }
  }
  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateTime(timestamp);
  }

  void _updateTime(DateTime timestamp) {
    if (_startTime == null) return;

    final elapsed =
        timestamp.difference(_startTime!).inMilliseconds;

    final totalMilliseconds =
        _baseMilliseconds + elapsed;

    // 通知を更新
    _updateNotification(
      Duration(milliseconds: totalMilliseconds),
    );

    // ★ Service → HomeScreen
    FlutterForegroundTask.sendDataToMain(
      {
        'totalMilliseconds': totalMilliseconds,
      },
    );
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
      ) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}