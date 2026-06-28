import 'package:flutter/material.dart';

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー検索')),
      body: const Center(
        child: Text('ユーザー検索画面'),
      ),
    );
  }
}