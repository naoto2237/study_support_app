// ======================================================================
// 【しくみ】今から勉強する教科（タイマーの近くでえらぶ）
//
// 主なクラス: CurrentSubject
// 使う場所: subject_picker.dart（えらぶボタン）／home_screen.dart（保存のとき）
// ・えらんだ教科は、スマホの中に覚えておく（次にアプリを開いても同じ教科）
// ・タイマーを止めて保存するとき、その時間を、この教科の時間としても記録する
//   （users/{uid}/studyRecords/{日付}.subjects.{教科}）
// ・タイマーが動いている間は変えられない（1回の計測を、1つの教科にするため）
// ======================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_support_app/data/profile_options.dart';

class CurrentSubject {
  CurrentSubject._();

  static const String _key = 'current_subject';

  // えらんでいる教科（えらんでいないときは null）
  static final ValueNotifier<String?> value = ValueNotifier<String?>(null);

  // アプリを開いたときに、前にえらんだ教科を読みこむ
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      value.value = ProfileOptions.subjects.contains(saved) ? saved : null;
    } catch (e) {
      debugPrint('教科を読みこめませんでした: $e');
    }
  }

  static Future<void> set(String? subject) async {
    value.value = (subject == null || subject.isEmpty) ? null : subject;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (value.value == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, value.value!);
      }
    } catch (e) {
      debugPrint('教科を保存できませんでした: $e');
    }
  }
}
