import 'package:flutter/material.dart';

class SearchRoomTab extends StatelessWidget {
  const SearchRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 検索バー
          TextField(
            decoration: InputDecoration(
              hintText: "ルーム名・資格名で検索",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 絞り込みボタン
          SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 絞り込み画面
              },
              icon: const Icon(Icons.filter_list),
              label: const Text("絞り込み"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3D96E8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "公開ルーム",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(title: "基本情報技術者", members: "35人"),

          const SizedBox(height: 15),

          const PublicRoomCard(title: "TOEIC 800点", members: "20人"),

          const SizedBox(height: 15),

          const PublicRoomCard(title: "簿記2級", members: "18人"),

          const SizedBox(height: 15),

          const PublicRoomCard(title: "応用情報技術者", members: "41人"),
        ],
      ),
    );
  }
}

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String members;

  const PublicRoomCard({super.key, required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.groups, color: Colors.green),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(members),
                    ],
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D96E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("参加"),
            ),
          ],
        ),
      ),
    );
  }
}
