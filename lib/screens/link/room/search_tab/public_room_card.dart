// ======================================================================
// 【部品】公開ルームのカード1枚分（「検索」タブの一覧に表示）
//
// 主なクラス: PublicRoomCard
// ・ルームへの参加、「入る」でルームの中（room_space_screen.dart）へ
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/room/space/room_space_screen.dart';

// =============================================================
// 公開ルームカード
// =============================================================

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String roomId;

  const PublicRoomCard({super.key, required this.title, required this.roomId});

  // ===========================================================
  // ルーム参加
  // ===========================================================

  Future<void> _joinRoom(BuildContext context) async {
    try {
      // -------------------------------------------------------
      // ユーザー取得
      // -------------------------------------------------------

      User? user = FirebaseAuth.instance.currentUser;

      // ログインしていなければ匿名ログイン
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw Exception("ユーザー情報を取得できませんでした");
      }

      // -------------------------------------------------------
      // ルーム取得
      // -------------------------------------------------------

      final roomRef = FirebaseFirestore.instance
          .collection("rooms")
          .doc(roomId);

      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception("このルームは存在しません");
      }

      final data = roomSnapshot.data() as Map<String, dynamic>;

      // -------------------------------------------------------
      // 公開ルームか確認
      // -------------------------------------------------------

      final bool isPublic = data["isPublic"] ?? false;

      if (!isPublic) {
        throw Exception("このルームは非公開です");
      }

      // -------------------------------------------------------
      // membersにユーザー追加
      // -------------------------------------------------------

      await roomRef.collection("members").doc(user.uid).set({
        "joinedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // -------------------------------------------------------
      // RoomSpaceScreenへ
      // -------------------------------------------------------

      if (!context.mounted) return;

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(
            roomTitle: data["title"] ?? title,

            roomId: roomId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ルームへの参加に失敗しました\n$e")));
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

        side: BorderSide(color: borderColor, width: 1),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: [
            // =================================================
            // アイコン
            // =================================================
            CircleAvatar(
              radius: 28,

              backgroundColor: isDark
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.green.shade100,

              child: const Icon(Icons.groups, color: Colors.green),
            ),

            const SizedBox(width: 15),

            // =================================================
            // ルーム情報
            // =================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontWeight: FontWeight.bold,

                      fontSize: 17,

                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ===========================================
                  // 参加人数
                  // ===========================================
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("rooms")
                        .doc(roomId)
                        .collection("members")
                        .snapshots(),

                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;

                      return Row(
                        children: [
                          Icon(Icons.people, size: 16, color: subtitleColor),

                          const SizedBox(width: 5),

                          Text(
                            "$count人",

                            style: TextStyle(color: subtitleColor),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // =================================================
            // 参加ボタン
            // =================================================
            ElevatedButton(
              onPressed: () async {
                // =============================================
                // 確認ダイアログ
                // =============================================

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

                // =============================================
                // 参加
                // =============================================

                if (result == true) {
                  if (!context.mounted) {
                    return;
                  }

                  await _joinRoom(context);
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D96E8),

                foregroundColor: Colors.white,

                elevation: 0,

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
