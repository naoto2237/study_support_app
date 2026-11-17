// ======================================================================
// 【しくみ】プロフィールを見た人・応援の記録
//
// 主なクラス: ProfileActivity
// ・見た人: users/{相手}/profileViews/{見た人のUID}
//     1人につき1つだけ（同じ人が何度見ても、人数は増えない）
//     lastViewedAt（最後に見た時刻）で、今週・今月に見た人を数える
// ・応援: users/{相手}/cheers/{応援した人のUID}_{日付}
//     応援しても、相手に通知は送らない
//     1人1日1回まで。date（"2026-11-16" の形）で、今週・今月の数を数える
// ・自分のページを開いたときは、見た人に数えない
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileActivity {
  ProfileActivity._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> viewsOf(String userId) {
    return _db.collection('users').doc(userId).collection('profileViews');
  }

  static CollectionReference<Map<String, dynamic>> cheersOf(String userId) {
    return _db.collection('users').doc(userId).collection('cheers');
  }

  // "2026-11-16" の形の日付
  static String dateIdOf(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // 今週の月曜日（0:00）
  static DateTime weekStartOf(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  // 今月の1日（0:00）
  static DateTime monthStartOf(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  // ==============================================================
  // 相手のプロフィールを見たことを記録する
  // ==============================================================
  static Future<void> recordView(String targetUserId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (me == null || targetUserId.isEmpty || me == targetUserId) return;

    try {
      final doc = viewsOf(targetUserId).doc(me);
      final snap = await doc.get();

      await doc.set({
        'viewerId': me,
        'lastViewedAt': FieldValue.serverTimestamp(),
        if (!snap.exists) 'firstViewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // 記録できなくても、プロフィールはそのまま見られるようにする
      debugPrint('プロフィールを見た記録に失敗しました: $e');
    }
  }

  // ==============================================================
  // 応援
  // ==============================================================

  static String _todayCheerId(String me) {
    return "${me}_${dateIdOf(DateTime.now())}";
  }

  // 今日、自分がこの人を応援したかどうか（変わったらすぐ伝わる）
  static Stream<bool> cheeredTodayStream(String targetUserId) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (me == null || targetUserId.isEmpty) return Stream.value(false);

    return cheersOf(
      targetUserId,
    ).doc(_todayCheerId(me)).snapshots().map((snap) => snap.exists);
  }

  // 応援する（今日すでに応援していたら何もしない）
  static Future<void> cheer(String targetUserId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (me == null || targetUserId.isEmpty || me == targetUserId) return;

    final now = DateTime.now();
    final doc = cheersOf(targetUserId).doc(_todayCheerId(me));

    if ((await doc.get()).exists) return;

    // 応援しても、相手に通知は送らない（応援の数だけ増える）
    await doc.set({
      'fromUserId': me,
      'date': dateIdOf(now),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
