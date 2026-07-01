import 'package:flutter/material.dart';

import 'user_search_screen.dart';
import 'qanda_screen.dart';
import 'room_screen_folder/room_screen.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Link'),
        centerTitle: true,
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
              subtitle: '質問・回答で学習をサポート',
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          size: 36,
          color: const Color(0xFF3D96E8)
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => screen,
            ),
          );
        },
      ),
    );
  }
}