import 'package:flutter/material.dart';
import 'package:study_support_app/setting_screen.dart';

import 'user_search_screen.dart';
import 'qanda_screen.dart';
import 'room_screen_folder/room_screen.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF258EDB),
        title: const Text(
          'Link',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMenuCard(
              context,
              icon: Icons.search,
              title: 'ユーザー検索',
              subtitle: '同じ目標を持つ学習仲間を探す',
              screen: const UserSearchScreen(),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.question_answer,
              title: 'Q&A',
              subtitle: '質問・回答で疑問を解決する',
              screen: QnAListPage(),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.groups,
              title: 'ルーム',
              subtitle: '同じ目標の仲間と交流する',
              screen: const RoomScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 36, color: const Color(0xFF258EDB)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
