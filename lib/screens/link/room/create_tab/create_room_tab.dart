// ======================================================================
// 【タブ】ルーム画面の「作成」タブ（自分のルーム一覧）
//
// 主なクラス: CreateRoomTab / _MyRoomList（一覧）
// ・自分のルームの一覧（1枚ずつのカードは room_card.dart）
// ・新しいルームの作成画面（room_making_screen.dart）を開く
// ・旧ファイル名: room_make.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:study_support_app/screens/link/room/create_tab/room_making_screen.dart';
import 'package:study_support_app/screens/link/room/create_tab/room_card.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);

    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      color: bgColor,

      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // =================================================
          // ルーム作成カード
          // =================================================
          InkWell(
            borderRadius: BorderRadius.circular(20),

            onTap: () {
              Navigator.push(
                context,

                MaterialPageRoute(builder: (_) => const RoomMakingScreen()),
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

                          style: TextStyle(color: Colors.white70, fontSize: 15),
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

          // =================================================
          // マイルーム
          // =================================================
          Text(
            "マイルーム",

            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 15),

          // =================================================
          // Firestore
          // =================================================
          _MyRoomList(),
        ],
      ),
    );
  }
}

// =============================================================
// マイルーム一覧
// =============================================================

class _MyRoomList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    final subtitleColor = isDark ? Colors.white60 : Colors.grey;

    // ---------------------------------------------------------
    // 現在のユーザー
    // ---------------------------------------------------------

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: cardColor,

          borderRadius: BorderRadius.circular(18),
        ),

        child: Text("ログインしてください", style: TextStyle(color: textColor)),
      );
    }

    // =========================================================
    // Firestore
    // =========================================================

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rooms")
          .where("ownerId", isEqualTo: user.uid)
          .snapshots(),

      builder: (context, snapshot) {
        // -----------------------------------------------------
        // 読み込み中
        // -----------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // -----------------------------------------------------
        // エラー
        // -----------------------------------------------------

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),

            child: Text(
              "ルームの取得に失敗しました\n${snapshot.error}",

              style: TextStyle(color: textColor),
            ),
          );
        }

        // -----------------------------------------------------
        // ルームなし
        // -----------------------------------------------------

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: cardColor,

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

        // -----------------------------------------------------
        // 新しい順に並べる
        // -----------------------------------------------------

        final rooms = snapshot.data!.docs.toList();

        rooms.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;

          final bData = b.data() as Map<String, dynamic>;

          final aTime = aData["createdAt"];

          final bTime = bData["createdAt"];

          if (aTime == null && bTime == null) {
            return 0;
          }

          if (aTime == null) {
            return 1;
          }

          if (bTime == null) {
            return -1;
          }

          return bTime.compareTo(aTime);
        });

        // -----------------------------------------------------
        // カード
        // -----------------------------------------------------

        return Column(
          children: rooms.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: RoomCard(
                docId: doc.id,

                title: data["title"] ?? "",

                isPublic: data["isPublic"] ?? false,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
