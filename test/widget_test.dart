// ======================================================================
// 【テスト】アプリの小さな部品が、思ったとおりに動くかを確かめる
//
// 動かし方: flutter test
// ・Firebase を使う画面は、ここではテストしない（つながる先が必要なため）
// ・時間の表示、日付の形、何もないときの表示など、計算と見た目の部品だけを見る
// ======================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_support_app/screens/mypage/custom_profile_fields.dart';
import 'package:study_support_app/screens/mypage/profile_activity.dart';
import 'package:study_support_app/screens/record/my_record/study_record_row.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/theme/empty_message.dart';

void main() {
  group('学習時間の表示（StudyRecordRow.formatStudyTime）', () {
    test('1分より短いときは、秒だけ', () {
      expect(StudyRecordRow.formatStudyTime(0), '0秒');
      expect(StudyRecordRow.formatStudyTime(45), '45秒');
    });

    test('1時間より短いときは、分と秒', () {
      expect(StudyRecordRow.formatStudyTime(60), '1分0秒');
      expect(StudyRecordRow.formatStudyTime(125), '2分5秒');
    });

    test('1時間以上のときは、時間と分（秒は出さない）', () {
      expect(StudyRecordRow.formatStudyTime(3600), '1時間0分');
      expect(StudyRecordRow.formatStudyTime(3 * 3600 + 25 * 60 + 9), '3時間25分');
    });
  });

  group('日付（ProfileActivity）', () {
    test('日付は "2026-01-05" の形になる', () {
      expect(ProfileActivity.dateIdOf(DateTime(2026, 1, 5)), '2026-01-05');
      expect(
        ProfileActivity.dateIdOf(DateTime(2026, 11, 19, 23, 59)),
        '2026-11-19',
      );
    });

    test('今週の始まりは、月曜日の0時', () {
      // 2026-11-19 は木曜日
      expect(
        ProfileActivity.weekStartOf(DateTime(2026, 11, 19, 15, 30)),
        DateTime(2026, 11, 16),
      );
      // 月曜日なら、その日
      expect(
        ProfileActivity.weekStartOf(DateTime(2026, 11, 16, 0, 1)),
        DateTime(2026, 11, 16),
      );
      // 日曜日なら、前の月曜日
      expect(
        ProfileActivity.weekStartOf(DateTime(2026, 11, 22, 23)),
        DateTime(2026, 11, 16),
      );
    });

    test('今月の始まりは、1日の0時', () {
      expect(
        ProfileActivity.monthStartOf(DateTime(2026, 11, 19, 8)),
        DateTime(2026, 11, 1),
      );
    });
  });

  group('えらぶ項目（ProfileOptions）', () {
    test('一覧にあるものだけ、学年・目標としてあつかう', () {
      expect(ProfileOptions.isGrade('高校2年'), isTrue);
      expect(ProfileOptions.isGrade('高2'), isFalse); // 前の自由入力
      expect(ProfileOptions.isGoal('大学受験'), isTrue);
      expect(ProfileOptions.isGoal(null), isFalse);
    });

    test('教科は「その他」で終わり、同じものが2回ない', () {
      expect(ProfileOptions.subjects.last, 'その他');
      expect(
        ProfileOptions.subjects.toSet().length,
        ProfileOptions.subjects.length,
      );
    });
  });

  group('1日分の行の、教科ごとの時間（StudyRecordRow）', () {
    test('記録から、教科ごとの時間を取り出す（0秒の教科は出さない）', () {
      expect(
        StudyRecordRow.subjectsOf({
          'studyTime': 5400,
          'subjects': {'数学': 4200, '英語': 1200, '国語': 0},
        }),
        {'数学': 4200, '英語': 1200},
      );
      expect(StudyRecordRow.subjectsOf({'studyTime': 60}), isEmpty);
    });

    test('教科をえらばずに計った分は「指定なし」になる', () {
      expect(
        StudyRecordRow.subjectsOf({
          'studyTime': 6000,
          'subjects': {'数学': 4200},
        }),
        {'数学': 4200, '指定なし': 1800},
      );
    });

    testWidgets('「指定なし」は、多くてもいちばん後ろ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyRecordRow(
              dateId: '2026-11-18',
              seconds: 4000,
              maxSeconds: 4000,
              textColor: Colors.black,
              secondaryColor: Colors.grey,
              subjects: {'指定なし': 3000, '英語': 1000},
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('英語 16分40秒')).dx,
        lessThan(tester.getTopLeft(find.text('指定なし 50分0秒')).dx),
      );
    });

    testWidgets('多い順に、教科と時間が出る', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyRecordRow(
              dateId: '2026-11-18',
              seconds: 5400,
              maxSeconds: 5400,
              textColor: Colors.black,
              secondaryColor: Colors.grey,
              subjects: {'英語': 1200, '数学': 4200},
            ),
          ),
        ),
      );

      expect(find.text('数学 1時間10分'), findsOneWidget);
      expect(find.text('英語 20分0秒'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('数学 1時間10分')).dx,
        lessThan(tester.getTopLeft(find.text('英語 20分0秒')).dx),
      );
    });
  });

  group('プロフィールの自由項目（CustomProfileField）', () {
    test('読むとき、空のものや形がちがうものはとばし、最大3こまで', () {
      final items = CustomProfileField.read([
        {'label': '趣味', 'value': '読書'},
        {'label': '', 'value': '中身だけ'},
        'こわれたデータ',
        for (int i = 0; i < 10; i++) {'label': '項目$i', 'value': '中身$i'},
      ]);

      expect(items.length, 3);
      expect(items.first.label, '趣味');
      expect(items.first.value, '読書');
      expect(CustomProfileField.read(null), isEmpty);
    });

    test('保存するとき、見出しか中身が空の行は入れない', () {
      final fields = [
        CustomProfileField(label: ' 好きな教科 ', value: '数学'),
        CustomProfileField(label: '空の中身', value: '  '),
      ];

      expect(CustomProfileField.toSave(fields), [
        {'label': '好きな教科', 'value': '数学'},
      ]);

      for (final f in fields) {
        f.dispose();
      }
    });
  });

  group('何もないときの表示（EmptyMessage）', () {
    testWidgets('文と説明が出る', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyMessage(
              icon: Icons.people_outline_rounded,
              text: 'まだ友達がいません',
              subText: '友達になると、ここに表示されます',
            ),
          ),
        ),
      );

      expect(find.text('まだ友達がいません'), findsOneWidget);
      expect(find.text('友達になると、ここに表示されます'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    });

    testWidgets('暗い画面でも、文が出る', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: EmptyMessage(
              icon: Icons.chat_outlined,
              text: 'まだメッセージはありません',
            ),
          ),
        ),
      );

      expect(find.text('まだメッセージはありません'), findsOneWidget);
    });
  });
}
