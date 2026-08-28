import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../room_space_folder/room_space.dart';

class SearchRoomTab extends StatelessWidget {
  const SearchRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F7F7);

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final textColor = isDark
        ? Colors.white70
        : Colors.black87;

    final subtitleColor = isDark
        ? Colors.white60
        : Colors.grey;

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==========================================
          // 検索バー
          // ==========================================

          TextField(
            style: TextStyle(
              color: textColor,
            ),
            cursorColor: const Color(0xFF3D96E8),
            decoration: InputDecoration(
              hintText: "ルーム名・資格名で検索",
              hintStyle: TextStyle(
                color: subtitleColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: subtitleColor,
              ),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF3D96E8),
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // 絞り込み
          // ==========================================

          SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 絞り込み画面
              },
              icon: const Icon(
                Icons.filter_list,
              ),
              label: const Text("絞り込み"),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor:
                const Color(0xFF3D96E8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                  side: BorderSide(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ==========================================
          // 公開ルーム
          // ==========================================

          Text(
            "公開ルーム",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "基本情報技術者",
            roomId: "basic_info",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "TOEIC 800点",
            roomId: "toeic_800",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "簿記2級",
            roomId: "bookkeeping_2",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "応用情報技術者",
            roomId: "applied_info",
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 公開ルームカード
// =========================================================

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String roomId;

  const PublicRoomCard({
    super.key,
    required this.title,
    required this.roomId,
  });

  // =========================================================
  // ルーム参加
  // =========================================================

  Future<void> _joinRoom(
      BuildContext context,
      ) async {
    try {
      User? user =
          FirebaseAuth.instance.currentUser;

      // ログインしていない場合
      // 匿名ログイン
      if (user == null) {
        final credential =
        await FirebaseAuth.instance
            .signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw Exception(
          "ユーザー情報を取得できませんでした",
        );
      }

      // ==========================================
      // ルームの存在確認
      // ==========================================

      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId);

      final roomSnapshot =
      await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception(
          "このルームは存在しません",
        );
      }

      // ==========================================
      // membersにユーザーを追加
      // ==========================================

      await roomRef
          .collection('members')
          .doc(user.uid)
          .set(
        {
          'joinedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ==========================================
      // RoomSpaceScreenへ移動
      // ==========================================

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(
            roomTitle: title,
            roomId: roomId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "ルームへの参加に失敗しました\n$e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final textColor = isDark
        ? Colors.white70
        : Colors.black87;

    final subtitleColor = isDark
        ? Colors.white60
        : Colors.grey;

    final borderColor = isDark
        ? Colors.grey.shade800
        : const Color(0xFFE5E7EB);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ==========================================
            // アイコン
            // ==========================================

            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? Colors.green.withValues(
                alpha: 0.2,
              )
                  : Colors.green.shade100,
              child: const Icon(
                Icons.groups,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 15),

            // ==========================================
            // ルーム情報
            // ==========================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ==========================================
                  // 現在の参加人数
                  // ==========================================

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .collection('members')
                        .snapshots(),
                    builder:
                        (context, snapshot) {
                      final count =
                          snapshot.data?.docs.length ??
                              0;

                      return Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: subtitleColor,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            "$count人",
                            style: TextStyle(
                              color:
                              subtitleColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ==========================================
            // 参加ボタン
            // ==========================================

            ElevatedButton(
              onPressed: () async {
                // ==============================
                // 参加確認ダイアログ
                // ==============================

                final result =
                await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor:
                      cardColor,

                      title: Text(
                        "ルームに入る",
                        style: TextStyle(
                          color: textColor,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      content: Text(
                        "「$title」に入りますか？",
                        style: TextStyle(
                          color:
                          subtitleColor,
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          child: Text(
                            "キャンセル",
                            style: TextStyle(
                              color:
                              subtitleColor,
                            ),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF3D96E8,
                            ),
                            foregroundColor:
                            Colors.white,
                          ),
                          child:
                          const Text("入る"),
                        ),
                      ],
                    );
                  },
                );

                // ==============================
                // 入る
                // ==============================

                if (result == true) {
                  if (!context.mounted) {
                    return;
                  }

                  await _joinRoom(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF3D96E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
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
