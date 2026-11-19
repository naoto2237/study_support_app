// ======================================================================
// 学習タイマーを、ホーム画面以外から動かすための窓口
//
// 主なクラス: StudyTimerRemote
// ・タイマーの本体はホーム画面の StopwatchWidget（stopwatch_widget.dart）だけ
// ・ルームの中（room_space_screen.dart）などは、ここを通して開始・停止・リセットする
//   （本体は1つなので、ホームとルームで二重に数えることはない。止めると本体が記録を保存する）
// ・本体の今の表示（時間の文字・計測中か）を、ValueNotifier で受け取れる
// ・勉強中かどうかを users/{uid}.studyingSince に保存して、ルームのメンバーに見せる
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StudyTimerRemote {
  StudyTimerRemote._();

  // 計測中か
  static final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);

  // ホームのタイマーに出ている時間（"01:23:45"。減るタイマーのときは残りの時間）
  static final ValueNotifier<String> timeText = ValueNotifier<String>(
    '00:00:00',
  );

  // 減るタイマーを使っているか
  static final ValueNotifier<bool> isCountdown = ValueNotifier<bool>(false);

  // タイマーの本体がつながっているか（ホーム画面が作られているか）
  static final ValueNotifier<bool> isAttached = ValueNotifier<bool>(false);

  static Future<void> Function()? _start;
  static Future<void> Function()? _stop;
  static Future<void> Function()? _reset;
  static Object? _owner;

  // ---------------- 本体（StopwatchWidget）が使う ----------------

  static void attach({
    required Object owner,
    required Future<void> Function() start,
    required Future<void> Function() stop,
    required Future<void> Function() reset,
  }) {
    _owner = owner;
    _start = start;
    _stop = stop;
    _reset = reset;
    isAttached.value = true;
  }

  static void detach(Object owner) {
    // あとからつながった別の本体を、まちがえて外さない
    if (_owner != owner) return;

    _owner = null;
    _start = null;
    _stop = null;
    _reset = null;
    isAttached.value = false;
    isRunning.value = false;
  }

  static void publish({
    required bool running,
    required String time,
    required bool countdown,
  }) {
    isRunning.value = running;
    timeText.value = time;
    isCountdown.value = countdown;
  }

  // ---------------- ほかの画面が使う ----------------

  static Future<void> start() async => _start?.call();

  static Future<void> stop() async => _stop?.call();

  static Future<void> reset() async => _reset?.call();

  // ---------------- 勉強中かどうかを、ほかの人にも知らせる ----------------
  // タイマーを始めたら users/{自分}.studyingSince に始めた時刻を入れ、止めたら消す。
  // ルームのメンバーの画面（room_member_screen.dart）で「勉強中」を出すのに使う。
  // 保存に失敗しても、タイマーは止めない（知らせるだけなので）

  static Future<void> markStudying(bool studying) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'studyingSince': studying
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('勉強中の状態を保存できませんでした: $e');
    }
  }

  // 消し忘れ（アプリが急に終わったときなど）で、ずっと「勉強中」にならないよう、
  // 始めてから12時間をこえたものは勉強中とみなさない
  static const Duration studyingLimit = Duration(hours: 12);

  static DateTime? studyingSinceOf(Map<String, dynamic>? userData) {
    final value = userData?['studyingSince'];
    if (value is! Timestamp) return null;

    final since = value.toDate();
    if (DateTime.now().difference(since) > studyingLimit) return null;
    return since;
  }
}
