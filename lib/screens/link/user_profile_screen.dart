// ======================================================================
// 【画面】相手側が見るプロフィール画面
//
// 主なクラス: UserProfileScreen
// 開き方: ユーザー検索画面でユーザーをタップ
// ・中身はマイページ画面（mypage_screen.dart）を相手の ID で表示しているだけ
// ・旧ファイル名: profile_screen.dart
// ======================================================================

import 'package:flutter/material.dart';

import 'package:study_support_app/screens/mypage/mypage_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MypageScreen(targetUserId: userId);
  }
}
