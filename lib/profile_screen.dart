//相手側が見るプロフィール画面


import 'package:flutter/material.dart';

import 'mypage_screen_folder/mypage_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MypageScreen(
      targetUserId: userId,
    );
  }
}