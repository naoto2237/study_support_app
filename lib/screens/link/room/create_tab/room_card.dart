// ======================================================================
// 【部品】自分のルームのカード1枚分（「作成」タブの一覧に表示）
//
// 主なクラス: RoomCard
// ・「入る」でルームの中（room_space_screen.dart）へ、ルームの削除
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/room/space/room_space_screen.dart';

// =============================================================
// ルームカード
// =============================================================

class RoomCard extends StatelessWidget {
  final String title;
  final bool isPublic;
  final String docId;

  const RoomCard({
    super.key,
    required this.docId,
    required this.title,
    required this.isPublic,
  });

  // ===========================================================
  // ルームを開く
  // ===========================================================

  Future<void> _openRoom(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("ログインしてください");
      }

      final roomRef = FirebaseFirestore.instance.collection("rooms").doc(docId);

      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception("このルームは存在しません");
      }

      await roomRef.collection("members").doc(user.uid).set({
        "joinedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(roomTitle: title, roomId: docId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ルームを開けませんでした\n$e")));
    }
  }

  // ===========================================================
  // ルーム削除
  // ===========================================================

  Future<void> _deleteRoom(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("ログインしてください");
      }

      final roomRef = FirebaseFirestore.instance.collection("rooms").doc(docId);

      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception("このルームは存在しません");
      }

      final data = roomSnapshot.data() as Map<String, dynamic>;

      // -------------------------------------------------------
      // 自分のルームか確認
      // -------------------------------------------------------

      if (data["ownerId"] != user.uid) {
        throw Exception("自分が作成したルームではありません");
      }

      await roomRef.delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ルームを削除しました")));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("削除に失敗しました\n$e")));
    }
  }

  // ===========================================================
  // Build
  // ===========================================================

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

        side: BorderSide(color: borderColor),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // =====================================================
        // アイコン
        // =====================================================
        leading: CircleAvatar(
          radius: 28,

          backgroundColor: isDark
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.blue.shade100,

          child: Icon(
            isPublic ? Icons.public : Icons.lock,

            color: const Color(0xFF3D96E8),
          ),
        ),

        // =====================================================
        // タイトル
        // =====================================================
        title: Text(
          title,

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: TextStyle(
            fontWeight: FontWeight.bold,

            fontSize: 17,

            color: textColor,
          ),
        ),

        // =====================================================
        // 公開設定 + 人数
        // =====================================================
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

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("rooms")
                    .doc(docId)
                    .collection("members")
                    .snapshots(),

                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;

                  return Text(
                    "$count人",

                    style: TextStyle(color: subtitleColor),
                  );
                },
              ),
            ],
          ),
        ),

        // =====================================================
        // メニュー
        // =====================================================
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subtitleColor),

          onSelected: (value) async {
            if (value == "delete") {
              final result = await showDialog<bool>(
                context: context,

                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor: cardColor,

                    title: Text(
                      "ルームを削除",

                      style: TextStyle(
                        color: textColor,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    content: Text(
                      "「$title」を削除しますか？",

                      style: TextStyle(color: subtitleColor),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },

                        child: Text(
                          "キャンセル",

                          style: TextStyle(color: subtitleColor),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },

                        child: const Text(
                          "削除",

                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                await _deleteRoom(context);
              }
            }
          },

          itemBuilder: (context) => [
            PopupMenuItem(
              value: "delete",

              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),

                  const SizedBox(width: 10),

                  const Text("削除", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),

        // =====================================================
        // ルームを開く
        // =====================================================
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,

            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: cardColor,

                title: Text(
                  "ルームに入る",

                  style: TextStyle(
                    color: textColor,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                content: Text(
                  "「$title」に入りますか？",

                  style: TextStyle(color: subtitleColor),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },

                    child: Text(
                      "キャンセル",

                      style: TextStyle(color: subtitleColor),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D96E8),

                      foregroundColor: Colors.white,
                    ),

                    child: const Text("入る"),
                  ),
                ],
              );
            },
          );

          if (result == true) {
            await _openRoom(context);
          }
        },
      ),
    );
  }
}
