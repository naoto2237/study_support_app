// ======================================================================
// 【データ】えらぶ項目の一覧（学年・職種／学習目標／教科）
//
// 主なクラス: ProfileOptions
// 使う場所: 登録（onboarding_screen.dart）／プロフィール編集（profile_edit_screen.dart）
//           タイマーの教科（subject_picker.dart）
//           絞り込み（ユーザー検索・ルームを探す・比較の相手選び）
//
// ・自由入力ではなく、この一覧からえらんでもらう（絞り込みで、同じ言葉どうしを比べられるように）
// ・保存するのは、ここの文字そのもの（例：users/{uid}.grade = "高校2年"）
// ・一覧を変えるときは、前に保存された文字と合わなくなるので、消さずに足すようにする
// ======================================================================

import 'package:flutter/material.dart';

class ProfileOptions {
  ProfileOptions._();

  // 学年・職種（1つえらぶ）
  static const List<String> grades = [
    '中学1年',
    '中学2年',
    '中学3年',
    '高校1年',
    '高校2年',
    '高校3年',
    '大学1年',
    '大学2年',
    '大学3年',
    '大学4年',
    '大学院',
    '専門学校',
    '社会人',
    'その他',
  ];

  // 学習目標の種類（1つえらぶ）
  static const List<String> goals = [
    '定期テスト',
    '高校受験',
    '大学受験',
    '資格試験',
    '語学',
    'プログラミング',
    '趣味・教養',
    'その他',
  ];

  // 教科（タイマーで、今から勉強するものを1つえらぶ）
  static const List<String> subjects = [
    '国語',
    '数学',
    '英語',
    '理科',
    '社会',
    '情報',
    'プログラミング',
    '資格',
    'その他',
  ];

  // 教科ごとのアイコンと色（記録の画面などで使う）
  // 色は青がメイン。ほかの色は、アイコンだけに使う
  static IconData subjectIcon(String subject) {
    switch (subject) {
      case '国語':
        return Icons.menu_book_rounded;
      case '数学':
        return Icons.calculate_outlined;
      case '英語':
        return Icons.translate_rounded;
      case '理科':
        return Icons.science_outlined;
      case '社会':
        return Icons.public_rounded;
      case '情報':
        return Icons.computer_rounded;
      case 'プログラミング':
        return Icons.code_rounded;
      case '資格':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  // 保存されている値が、一覧の中にあるか（前の自由入力の人は、ない）
  static bool isGrade(String? value) => grades.contains(value);
  static bool isGoal(String? value) => goals.contains(value);
}
