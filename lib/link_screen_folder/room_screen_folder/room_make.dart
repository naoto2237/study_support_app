import 'package:flutter/material.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ルーム作成カード
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: ルーム作成画面へ
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(width: 18),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ルームを作る",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "同じ目標を持つ仲間を集めよう",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "マイルーム",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "基本情報技術者試験",
          members: "23人",
          isPublic: true,
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "TOEIC 800点",
          members: "14人",
          isPublic: false,
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "応用情報技術者",
          members: "31人",
          isPublic: true,
        ),
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  final String title;
  final String members;
  final bool isPublic;

  const RoomCard({
    super.key,
    required this.title,
    required this.members,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(
            Icons.groups,
            color: Colors.blue,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                isPublic ? Icons.public : Icons.lock,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(isPublic ? "公開" : "非公開"),
              const SizedBox(width: 15),
              const Icon(
                Icons.people,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(members),
            ],
          ),
        ),

        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () {},
      ),
    );
  }
}