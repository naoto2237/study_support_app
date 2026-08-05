import 'package:flutter/material.dart';
import 'room_making.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../room_space.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF7F7F7), // ← 背景色

      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ルーム作成カード
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoomMakingScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3D96E8),
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ルームを作る",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "同じ目標を持つ仲間を集めよう",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 1.00),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "マイルーム",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("rooms")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 50, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "まだルームを作成していません",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "「ルームを作る」から作成しましょう",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: RoomCard(
                      docId: doc.id,
                      title: data["title"] ?? "",
                      members: "${data["members"]}人",
                      isPublic: data["isPublic"] ?? true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String title;
  final String members;
  final bool isPublic;
  final String docId;

  const RoomCard({
    super.key,
    required this.docId,
    required this.title,
    required this.members,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.groups, color: const Color(0xFF3D96E8)),
        ),

        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(members),
            ],
          ),
        ),

        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case "edit":
                // TODO: 編集画面へ遷移
                break;

              case "delete":
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("ルームを削除"),
                    content: const Text("このルームを削除しますか？"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("キャンセル"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "削除",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (result == true) {
                  await FirebaseFirestore.instance
                      .collection("rooms")
                      .doc(docId)
                      .delete();
                }
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 10), Text("編集")],
              ),
            ),
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("削除", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("ルームに入る"),
              content: Text("「$title」に入りますか？"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D96E8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("入る"),
                ),
              ],
            ),
          );

          if (result == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomSpaceScreen(
                  roomTitle: title,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
