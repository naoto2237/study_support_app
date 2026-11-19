// ======================================================================
// 【しくみ】目標を達成した日の数を、プロフィールに出せるように保存する
//
// 主な関数: AchievementCounter.sync
// 使う場所: my_record_screen.dart（その日の結果を保存したとき）
//           mypage_profile_section.dart（自分のマイページを開いたとき）
//
// ・学習記録を非公開にした人の記録は、ほかの人は読めない（Firestore のルール）。
//   でも「目標達成」の数は、非公開でもプロフィールに出す。
// ・そのため、本人が数えた数を users/{自分}.goalAchievedDays に保存しておき、
//   ほかの人はその数を読む
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AchievementCounter {
  AchievementCounter._();

  static const String field = 'goalAchievedDays';

  // 自分の達成した日を数えなおして、変わっていたら保存する
  static Future<void> sync() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final count = await userRef
          .collection('studyRecords')
          .where('goalAchieved', isEqualTo: true)
          .count()
          .get();

      final days = count.count ?? 0;

      final userDoc = await userRef.get();
      if (userDoc.data()?[field] == days) return;

      await userRef.set({field: days}, SetOptions(merge: true));
    } catch (e) {
      // 保存できなくても、ほかの機能には関係ないので、ログに残すだけ
      debugPrint('目標達成の数を保存できませんでした: $e');
    }
  }
}
