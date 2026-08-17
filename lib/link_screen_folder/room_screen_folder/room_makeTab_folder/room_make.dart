import 'package:flutter/material.dart';
import 'room_making.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../room_space_folder/room_space.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      color: bgColor, // ← 背景色

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

                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            "マイルーム",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
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
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 50, color: subtitleColor),
                      const SizedBox(height: 12),
                      Text(
                        "まだルームを作成していません",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "「ルームを作る」から作成しましょう",
                        style: TextStyle(color: subtitleColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade100,
          child: const Icon(Icons.groups, color: Color(0xFF3D96E8)),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                isPublic ? Icons.public : Icons.lock,
                size: 16,
                color: subtitleColor,
              ),
              const SizedBox(width: 5),
              Text(
                isPublic ? "公開" : "非公開",
                style: TextStyle(color: subtitleColor),
              ),
              const SizedBox(width: 15),
              Icon(Icons.people, size: 16, color: subtitleColor),
              const SizedBox(width: 5),
              Text(
                members,
                style: TextStyle(color: subtitleColor),
              ),
            ],
          ),
        ),

        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subtitleColor),
          onSelected: (value) async {
            switch (value) {
              case "edit":
              // TODO: 編集画面へ遷移
                break;

              case "delete":
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: cardColor,
                    title: Text("ルームを削除", style: TextStyle(color: textColor)),
                    content: Text("このルームを削除しますか？", style: TextStyle(color: subtitleColor)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("キャンセル", style: TextStyle(color: subtitleColor)),
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
          itemBuilder: (context) => [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(Icons.edit, color: textColor),
                  const SizedBox(width: 10),
                  Text("編集", style: TextStyle(color: textColor)),
                ],
              ),
            ),
            const PopupMenuItem(
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
              backgroundColor: cardColor,
              title: Text("ルームに入る", style: TextStyle(color: textColor)),
              content: Text("「$title」に入りますか？", style: TextStyle(color: subtitleColor)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("キャンセル", style: TextStyle(color: subtitleColor)),
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
                  roomId: docId,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}