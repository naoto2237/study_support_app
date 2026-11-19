// ======================================================================
// 【部品】自分のルームのカード1枚分（「作成」タブの一覧に表示）
//
// 主なクラス: RoomCard
// ・「入る」でルームの中（room_space_screen.dart）へ、ルームの削除
// ・見た目は room_card_body.dart（「検索」タブのカードと同じ形）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/room/space/room_space_screen.dart';
import 'package:study_support_app/screens/link/room/room_card_body.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

// =============================================================
// ルームカード
// =============================================================

class RoomCard extends StatelessWidget {
  final String title;
  final bool isPublic;
  final String ownerId;
  final String docId;
  final String description;

  const RoomCard({
    super.key,
    required this.docId,
    required this.title,
    required this.isPublic,
    this.ownerId = "",
    this.description = "",
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

      // まだメンバーでないときだけ、参加した時刻を入れる
      // （入るたびに入れると、参加した時刻が今に変わり、
      //   ルームの「最近のできごと」に「参加しました」が何度も出てしまう）
      final memberRef = roomRef.collection("members").doc(user.uid);
      final memberSnapshot = await memberRef.get();

      if (!memberSnapshot.exists) {
        await memberRef.set({"joinedAt": FieldValue.serverTimestamp()});
      }

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
  // Build（見た目は room_card_body.dart。「検索」タブのカードと同じ形）
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return RoomCardBody(
      roomId: docId,
      title: title,
      description: description,
      isPublic: isPublic,
      ownerId: ownerId,

      // ルームを開く（確かめてから入る）
      onTap: () async {
        final result = await _confirm(
          context,
          title: "ルームに入る",
          message: "「$title」に入りますか？",
          okText: "入る",
        );

        if (result == true && context.mounted) {
          await _openRoom(context);
        }
      },

      // 右のメニュー（削除）
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: p.muted),
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          if (value != "delete") return;

          final result = await _confirm(
            context,
            title: "ルームを削除",
            message: "「$title」を削除しますか？",
            okText: "削除",
            okColor: AppColors.red,
          );

          if (result == true && context.mounted) {
            await _deleteRoom(context);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: "delete",
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: AppColors.red),
                SizedBox(width: 10),
                Text("削除", style: TextStyle(color: AppColors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 確かめる小さな画面（ほかの画面のダイアログと同じ形）
Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String okText,
  Color okColor = AppColors.primary,
}) {
  final p = context.pal;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: p.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: TextStyle(color: p.text, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("キャンセル", style: TextStyle(color: p.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              okText,
              style: TextStyle(color: okColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
