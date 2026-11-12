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
import 'package:study_support_app/theme/app_colors.dart';

class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      color: bgColor,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),

        children: [
          // =================================================
          // ルーム作成カード
          // =================================================
          InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: () {
              Navigator.push(
                context,

                MaterialPageRoute(builder: (_) => const RoomMakingScreen()),
              );
            },

            child: Container(
              // 上下の余白をそろえて、中身をカードのまん中に置く
              padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),

              decoration: BoxDecoration(
                color: AppColors.primary,

                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      color: Colors.white24,

                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.group_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "ルームを作る",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "同じ目標を持つ仲間を集めよう",

                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // =================================================
          // マイルーム
          // =================================================
          Text(
            "マイルーム",

            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 10),

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
                color: isDark ? Colors.grey.shade800 : AppColors.border,
              ),
            ),

            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.primarySoft,
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "まだルームを作成していません",

                  style: TextStyle(fontSize: 15, color: textColor),
                ),

                const SizedBox(height: 6),

                Text(
                  "「ルームを作る」から作成しましょう",

                  style: TextStyle(fontSize: 12.5, color: subtitleColor),
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
