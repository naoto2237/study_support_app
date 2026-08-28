import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'room_making.dart';
import '../room_space_folder/room_space.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F7F7);

    final textColor = isDark
        ? Colors.white70
        : Colors.black87;

    final cardBgColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final subtitleColor = isDark
        ? Colors.white60
        : Colors.grey;

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==========================================
          // ルーム作成カード
          // ==========================================

          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const RoomMakingScreen(),
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
                      borderRadius:
                      BorderRadius.circular(16),
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ルームを作る",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
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

          // ==========================================
          // マイルーム
          // ==========================================

          Text(
            "マイルーム",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 15),

          // ==========================================
          // Firestoreからルームを取得
          // ==========================================

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("rooms")
                .orderBy(
              "createdAt",
              descending: true,
            )
                .snapshots(),

            builder: (context, snapshot) {
              // ----------------------------------------
              // 読み込み中
              // ----------------------------------------

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // ----------------------------------------
              // エラー
              // ----------------------------------------

              if (snapshot.hasError) {
                return Container(
                  padding:
                  const EdgeInsets.all(20),
                  child: Text(
                    "ルームの取得に失敗しました\n${snapshot.error}",
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                );
              }

              // ----------------------------------------
              // ルームがない
              // ----------------------------------------

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 40,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 50,
                        color: subtitleColor,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "まだルームを作成していません",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "「ルームを作る」から作成しましょう",
                        style: TextStyle(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ----------------------------------------
              // ルーム一覧
              // ----------------------------------------

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data =
                  doc.data()
                  as Map<String, dynamic>;

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 15,
                    ),
                    child: RoomCard(
                      docId: doc.id,
                      title: data["title"] ?? "",
                      isPublic:
                      data["isPublic"] ?? true,
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

// =========================================================
// ルームカード
// =========================================================

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

  // =========================================================
  // ルームに参加する
  // =========================================================

  Future<void> _joinRoom(
      BuildContext context,
      ) async {
    try {
      // ----------------------------------------
      // Firebase Authenticationのユーザー取得
      // ----------------------------------------

      User? user =
          FirebaseAuth.instance.currentUser;

      // ログインしていなければ匿名ログイン
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

      // ----------------------------------------
      // ルーム
      // ----------------------------------------

      final roomRef = FirebaseFirestore.instance
          .collection("rooms")
          .doc(docId);

      // ----------------------------------------
      // ルームが存在するか確認
      // ----------------------------------------

      final roomSnapshot =
      await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception(
          "このルームは存在しません",
        );
      }

      // ----------------------------------------
      // membersにユーザーを追加
      // ----------------------------------------

      await roomRef
          .collection("members")
          .doc(user.uid)
          .set(
        {
          "joinedAt":
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ----------------------------------------
      // RoomSpaceScreenへ移動
      // ----------------------------------------

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(
            roomTitle: title,
            roomId: docId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "ルームへの参加に失敗しました\n$e",
          ),
        ),
      );
    }
  }

  // =========================================================
  // ルーム削除
  // =========================================================

  Future<void> _deleteRoom(
      BuildContext context,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection("rooms")
          .doc(docId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "ルームを削除しました",
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "ルームの削除に失敗しました\n$e",
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
      child: ListTile(
        contentPadding:
        const EdgeInsets.all(16),

        // ==========================================
        // アイコン
        // ==========================================

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isDark
              ? Colors.blue.withValues(
            alpha: 0.2,
          )
              : Colors.blue.shade100,
          child: const Icon(
            Icons.groups,
            color: Color(0xFF3D96E8),
          ),
        ),

        // ==========================================
        // タイトル
        // ==========================================

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),

        // ==========================================
        // 公開・参加人数
        // ==========================================

        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                isPublic
                    ? Icons.public
                    : Icons.lock,
                size: 16,
                color: subtitleColor,
              ),

              const SizedBox(width: 5),

              Text(
                isPublic ? "公開" : "非公開",
                style: TextStyle(
                  color: subtitleColor,
                ),
              ),

              const SizedBox(width: 15),

              Icon(
                Icons.people,
                size: 16,
                color: subtitleColor,
              ),

              const SizedBox(width: 5),

              // ======================================
              // membersサブコレクションの人数
              // ======================================

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("rooms")
                    .doc(docId)
                    .collection("members")
                    .snapshots(),

                builder:
                    (context, memberSnapshot) {
                  final count =
                      memberSnapshot.data?.docs.length ??
                          0;

                  return Text(
                    "$count人",
                    style: TextStyle(
                      color: subtitleColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // ==========================================
        // メニュー
        // ==========================================

        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: subtitleColor,
          ),

          onSelected: (value) async {
            switch (value) {
            // --------------------------------------
            // 編集
            // --------------------------------------

              case "edit":
              // TODO:
              // 編集画面へ遷移
                break;

            // --------------------------------------
            // 削除
            // --------------------------------------

              case "delete":
                final result =
                await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor:
                      cardColor,

                      title: Text(
                        "ルームを削除",
                        style: TextStyle(
                          color: textColor,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      content: Text(
                        "このルームを削除しますか？",
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

                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          child: const Text(
                            "削除",
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (result == true) {
                  await _deleteRoom(
                    context,
                  );
                }

                break;
            }
          },

          itemBuilder: (context) => [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: textColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "編集",
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "削除",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ==========================================
        // ルームを開く
        // ==========================================

        onTap: () async {
          final result =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: cardColor,

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
                    color: subtitleColor,
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
                        color: subtitleColor,
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
                    ElevatedButton.styleFrom(
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

          if (result == true) {
            await _joinRoom(context);
          }
        },
      ),
    );
  }
}
