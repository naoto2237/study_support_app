import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('1日の目標時間'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 目標時間設定画面へ
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('通知設定'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 通知設定画面へ
            },
          ),
          const Divider(height: 1),

          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('ダークモード'),
            value: false,
            onChanged: (value) {
              // ON/OFFの処理
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('学習履歴'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 学習履歴画面へ
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリについて'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // アプリ情報画面へ
            },
          ),
        ],
      ),
    );
  }
}